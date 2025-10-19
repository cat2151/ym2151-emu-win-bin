# Rust用ライブラリビルド計画書

## 概要

Nuked-OPMライブラリをWindows向けにビルドし、Rustプロジェクトから利用可能な静的ライブラリ (.a または .lib) を生成します。

## ビルド成果物

- **ファイル名**: `libym2151.a` (Linux/MinGW) または `ym2151.lib` (MSVC)
- **形式**: 静的ライブラリ
- **用途**: Rustプロジェクトの `Cargo.toml` で直接リンク可能

## アーキテクチャ

```
src/rust/
├── Cargo.toml          # ライブラリプロジェクト設定
├── build.rs            # ビルドスクリプト（Nuked-OPMのコンパイル）
├── src/
│   └── lib.rs          # ライブラリエントリポイント（FFIバインディング）
└── vendor/
    └── nuked-opm/      # Nuked-OPMソースコード (git submodule)
        ├── opm.h
        └── opm.c
```

## 依存関係

### Cargo.toml

```toml
[package]
name = "ym2151"
version = "0.1.0"
edition = "2021"

[lib]
name = "ym2151"
crate-type = ["staticlib", "cdylib"]  # 静的と動的両方

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
cargo init --lib --name ym2151
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

**src/lib.rs**:
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

// このライブラリは他の言語から利用されることを想定
// Rustから使う場合のラッパーは別途実装可能
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

# ビルド（静的ライブラリ）
cd src/rust
cargo build --release --target x86_64-pc-windows-gnu --lib

# 成果物の場所
# target/x86_64-pc-windows-gnu/release/libym2151.a
# target/x86_64-pc-windows-gnu/release/ym2151.dll (cdylibの場合)
```

### 静的リンク設定

**.cargo/config.toml** を作成:
```toml
[target.x86_64-pc-windows-gnu]
rustflags = ["-C", "target-feature=+crt-static"]
linker = "x86_64-w64-mingw32-gcc"
ar = "x86_64-w64-mingw32-ar"
```

## テスト方法

### ライブラリの確認

```bash
# ライブラリファイルの確認
file target/x86_64-pc-windows-gnu/release/libym2151.a

# シンボルの確認
x86_64-w64-mingw32-nm target/x86_64-pc-windows-gnu/release/libym2151.a | grep OPM
```

### DLL依存の確認（cdylibの場合）

```bash
# DLL依存の確認（mingw DLLがないことを確認）
x86_64-w64-mingw32-objdump -p target/x86_64-pc-windows-gnu/release/ym2151.dll | grep -i "dll"
```

## 利用例

### Rustプロジェクトから利用

```toml
# Cargo.toml
[dependencies]
ym2151 = { path = "../path/to/ym2151" }
```

### 他言語から利用

生成された `libym2151.a` は以下のように利用可能：

- **C/C++**: `gcc -o myapp myapp.c -L. -lym2151`
- **Go**: CGOの `#cgo LDFLAGS: -L. -lym2151`
- **Python**: ctypes経由でDLL版を利用

## 実装優先度

1. **高**: 基本的なプロジェクト構造とビルドシステム
2. **高**: Nuked-OPMの静的ライブラリとしてのコンパイル
3. **高**: FFIバインディングのエクスポート
4. **中**: cdylib形式でのビルド（DLL）
5. **低**: ドキュメントの充実

## 技術的課題と対策

### 課題1: 静的ライブラリのクロスコンパイル
- **対策**: cc crateがminGWコンパイラを自動検出。明示的に指定も可能

### 課題2: シンボルのエクスポート
- **対策**: `extern "C"` でC互換のシンボルをエクスポート

### 課題3: mingw DLL依存
- **対策**: `target-feature=+crt-static` で完全静的リンク

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- Rust FFI: https://doc.rust-lang.org/nomicon/ffi.html
- cc crate: https://docs.rs/cc/
- Cargo book (cdylib): https://doc.rust-lang.org/cargo/reference/cargo-targets.html#library
