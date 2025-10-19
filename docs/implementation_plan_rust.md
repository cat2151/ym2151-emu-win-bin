# Rust実装計画書

## 概要

Rustで、Nuked-OPMライブラリを使用したYM2151エミュレータCLIを作成します。
音声出力には`cpal`ライブラリを使用し、Windows向けに静的リンクされた実行ファイルを生成します。

## アーキテクチャ

```
src/rust/
├── Cargo.toml          # プロジェクト設定
├── build.rs            # ビルドスクリプト（Nuked-OPMのコンパイル）
├── src/
│   ├── main.rs         # エントリポイント
│   ├── ym2151.rs       # YM2151エミュレータFFIバインディング
│   └── audio.rs        # 音声出力ハンドラ
└── vendor/
    └── nuked-opm/      # Nuked-OPMソースコード (git submodule)
        ├── opm.h
        └── opm.c
```

## 依存関係

### Cargo.toml

```toml
[package]
name = "ym2151-emu"
version = "0.1.0"
edition = "2021"

[dependencies]
cpal = "0.15"
anyhow = "1.0"
clap = { version = "4.4", features = ["derive"] }

[build-dependencies]
cc = "1.0"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
strip = true
```

## 実装ステップ

### 1. プロジェクト初期化

```bash
cd src/rust
cargo init --name ym2151-emu
```

### 2. Nuked-OPMの統合

**build.rs** の作成:
```rust
use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let nuked_opm_dir = manifest_dir.join("vendor/nuked-opm");

    // Nuked-OPMのコンパイル
    cc::Build::new()
        .file(nuked_opm_dir.join("opm.c"))
        .include(&nuked_opm_dir)
        .opt_level(3)
        .compile("nuked-opm");

    println!("cargo:rerun-if-changed=vendor/nuked-opm/opm.c");
    println!("cargo:rerun-if-changed=vendor/nuked-opm/opm.h");
}
```

### 3. FFIバインディングの実装

**src/ym2151.rs**:
```rust
use std::os::raw::{c_void, c_uint};

#[repr(C)]
pub struct OpmChip {
    _private: [u8; 0],
}

extern "C" {
    pub fn OPM_Reset(chip: *mut OpmChip);
    pub fn OPM_Write(chip: *mut OpmChip, port: c_uint, data: c_uint);
    pub fn OPM_Clock(chip: *mut OpmChip, buffer: *mut i16, frames: c_uint);
}

pub struct Ym2151 {
    chip: Box<OpmChip>,
}

impl Ym2151 {
    pub fn new() -> Self {
        // チップの初期化実装
        todo!()
    }

    pub fn reset(&mut self) {
        unsafe { OPM_Reset(self.chip.as_mut()) }
    }

    pub fn write(&mut self, register: u8, value: u8) {
        unsafe { OPM_Write(self.chip.as_mut(), register as c_uint, value as c_uint) }
    }

    pub fn generate_samples(&mut self, buffer: &mut [i16]) {
        unsafe {
            OPM_Clock(
                self.chip.as_mut(),
                buffer.as_mut_ptr(),
                buffer.len() as c_uint / 2, // stereo
            )
        }
    }
}
```

### 4. 音声出力の実装

**src/audio.rs**:
```rust
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use cpal::{Device, Stream, StreamConfig};
use std::sync::{Arc, Mutex};
use anyhow::Result;

pub struct AudioOutput {
    stream: Stream,
    device: Device,
}

impl AudioOutput {
    pub fn new(sample_rate: u32) -> Result<Self> {
        let host = cpal::default_host();
        let device = host.default_output_device()
            .ok_or_else(|| anyhow::anyhow!("No output device available"))?;

        let config = StreamConfig {
            channels: 2,
            sample_rate: cpal::SampleRate(sample_rate),
            buffer_size: cpal::BufferSize::Default,
        };

        // ストリーム作成実装
        todo!()
    }

    pub fn play(&self) -> Result<()> {
        self.stream.play()?;
        Ok(())
    }
}
```

### 5. メイン実装

**src/main.rs**:
```rust
use clap::Parser;
use anyhow::Result;

mod ym2151;
mod audio;

#[derive(Parser)]
#[command(name = "ym2151-emu")]
#[command(about = "YM2151 Emulator CLI", long_about = None)]
struct Args {
    /// Sample rate
    #[arg(short, long, default_value_t = 44100)]
    sample_rate: u32,

    /// Duration in seconds
    #[arg(short, long, default_value_t = 5)]
    duration: u32,
}

fn main() -> Result<()> {
    let args = Args::parse();

    println!("YM2151 Emulator starting...");
    println!("Sample rate: {} Hz", args.sample_rate);
    println!("Duration: {} seconds", args.duration);

    // YM2151の初期化
    let mut ym2151 = ym2151::Ym2151::new();
    ym2151.reset();

    // デモ音声の設定（例: 440Hz正弦波）
    // レジスタ設定の実装

    // 音声出力の開始
    let audio = audio::AudioOutput::new(args.sample_rate)?;
    audio.play()?;

    // 指定時間再生
    std::thread::sleep(std::time::Duration::from_secs(args.duration as u64));

    println!("Playback finished.");
    Ok(())
}
```

## ビルド方法

### WSL2でのクロスコンパイル

```bash
# Rustのセットアップ
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add x86_64-pc-windows-gnu

# MinGWのインストール
sudo apt-get update
sudo apt-get install -y mingw-w64

# ビルド
cd src/rust
cargo build --release --target x86_64-pc-windows-gnu

# 静的リンクの確認
file target/x86_64-pc-windows-gnu/release/ym2151-emu.exe
```

### 静的リンク設定

**.cargo/config.toml** を作成:
```toml
[target.x86_64-pc-windows-gnu]
rustflags = ["-C", "target-feature=+crt-static"]
```

## テスト方法

### WSL2からWindowsバイナリを実行

```bash
# Windows側で実行
/mnt/c/Windows/System32/cmd.exe /c target/x86_64-pc-windows-gnu/release/ym2151-emu.exe --duration 3
```

### 依存関係の確認

```bash
# DLL依存の確認（mingw DLLがないことを確認）
objdump -p target/x86_64-pc-windows-gnu/release/ym2151-emu.exe | grep -i "dll"
```

## 実装優先度

1. **高**: 基本的なプロジェクト構造とビルドシステム
2. **高**: Nuked-OPMのFFIバインディング
3. **高**: 音声出力の基本実装
4. **中**: デモ音声の実装（440Hz正弦波など）
5. **中**: コマンドライン引数の処理
6. **低**: エラーハンドリングの改善
7. **低**: より複雑な音声パターンのサポート

## 技術的課題と対策

### 課題1: cpalのWindows静的リンク
- **対策**: WASAPI バックエンドは動的リンクが不要。`cpal` の features を適切に設定

### 課題2: Nuked-OPMの初期化
- **対策**: Nuked-OPMのヘッダファイルを詳細に読み、正しい初期化シーケンスを実装

### 課題3: オーディオバッファの同期
- **対策**: リングバッファを使用してYM2151の生成とオーディオ出力を非同期化

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- cpal: https://docs.rs/cpal/
- Rust FFI: https://doc.rust-lang.org/nomicon/ffi.html
- cc crate: https://docs.rs/cc/
