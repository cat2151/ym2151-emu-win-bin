# Rust Nuked-OPM Library

公式Nuked-OPM (https://github.com/nukeykt/Nuked-OPM) をWindows向けにビルドし、静的・動的ライブラリを生成します。

## 重要: このライブラリについて

このライブラリは**公式Nuked-OPMのビルド成果物**であり、カスタムラッパーではありません。
すべての関数は公式opm.hで定義されているものと同じシグネチャで提供されます。

## ビルド方法

```bash
# リポジトリのルートから実行
bash scripts/build_rust.sh
```

このスクリプトは以下を実行します：
1. Nuked-OPMをvendor/nuked-opmにクローン（未取得の場合）
2. .cargo/config.tomlを生成（静的リンク設定）
3. x86_64-pc-windows-gnuターゲットでビルド

## 成果物

- `target/x86_64-pc-windows-gnu/release/libnukedopm.a` - 静的ライブラリ
- `target/x86_64-pc-windows-gnu/release/nukedopm.dll` - 動的ライブラリ

**注意**: ライブラリ名は `nukedopm` ですが、エクスポートされる関数は公式の `OPM_*` です。

## 前提条件

- Rust (rustup)
- mingw-w64 (`x86_64-w64-mingw32-gcc`)
- x86_64-pc-windows-gnuターゲット (`rustup target add x86_64-pc-windows-gnu`)

## 利用方法（公式API）

このライブラリは公式Nuked-OPM APIを提供します：

```rust
// Rustから使用する例
use std::os::raw::{c_uint, c_int};

#[repr(C)]
struct opm_t {
    // 実際の構造体は非常に大きいため、不透明型として扱うことを推奨
    _data: [u8; 4096]
}

extern "C" {
    // 公式Nuked-OPM API (opm.hより)
    fn OPM_Reset(chip: *mut opm_t);
    fn OPM_Write(chip: *mut opm_t, port: u32, data: u8);
    fn OPM_Clock(chip: *mut opm_t, output: *mut i32, sh1: *mut u8, sh2: *mut u8, so: *mut u8);
    fn OPM_Read(chip: *mut opm_t, port: u32) -> u8;
    fn OPM_ReadIRQ(chip: *mut opm_t) -> u8;
    fn OPM_ReadCT1(chip: *mut opm_t) -> u8;
    fn OPM_ReadCT2(chip: *mut opm_t) -> u8;
    fn OPM_SetIC(chip: *mut opm_t, ic: u8);
}

fn main() {
    let mut chip = Box::new(opm_t { _data: [0; 4096] });
    unsafe {
        OPM_Reset(chip.as_mut());
        // ... use the chip
    }
}
```

詳細なAPIドキュメントは公式リポジトリを参照：
https://github.com/nukeykt/Nuked-OPM/blob/master/opm.h
