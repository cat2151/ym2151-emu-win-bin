# Rust YM2151 Library

Nuked-OPMライブラリをWindows向けにビルドし、Rustプロジェクトから利用可能な静的ライブラリを生成します。

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

- `target/x86_64-pc-windows-gnu/release/libym2151.a` - 静的ライブラリ
- `target/x86_64-pc-windows-gnu/release/ym2151.dll` - 動的ライブラリ（cdylibの場合）

## 前提条件

- Rust (rustup)
- mingw-w64 (`x86_64-w64-mingw32-gcc`)
- x86_64-pc-windows-gnuターゲット (`rustup target add x86_64-pc-windows-gnu`)

## 利用方法

生成されたライブラリは他の言語から利用できます：

```rust
// Rustから
extern "C" {
    fn OPM_Reset(chip: *mut c_void);
    fn OPM_Write(chip: *mut c_void, port: u32, data: u32);
    fn OPM_Clock(chip: *mut c_void, buffer: *mut i16, frames: u32);
}
```
