#!/bin/bash
set -e

echo "========================================="
echo "Building Rust YM2151 Library for Windows"
echo "========================================="

cd src/rust

# Nuked-OPMのダウンロード（git submoduleまたは直接ダウンロード）
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# .cargo/config.tomlの作成（静的リンク設定）
mkdir -p .cargo
cat > .cargo/config.toml << 'EOF'
[target.x86_64-pc-windows-gnu]
rustflags = ["-C", "target-feature=+crt-static"]
linker = "x86_64-w64-mingw32-gcc"
ar = "x86_64-w64-mingw32-ar"
EOF

# ビルド（ライブラリ）
echo "Building Rust library..."
cargo build --release --target x86_64-pc-windows-gnu --lib

# 確認
echo "Build completed!"
echo "Static library:"
ls -lh target/x86_64-pc-windows-gnu/release/libym2151.a 2>/dev/null || echo "  libym2151.a not found"
echo "Dynamic library:"
ls -lh target/x86_64-pc-windows-gnu/release/ym2151.dll 2>/dev/null || echo "  ym2151.dll not found"

# シンボルの確認
if [ -f "target/x86_64-pc-windows-gnu/release/libym2151.a" ]; then
    echo "Checking symbols in static library..."
    x86_64-w64-mingw32-nm target/x86_64-pc-windows-gnu/release/libym2151.a | grep OPM | head -5
fi

# DLL依存の確認（cdylibの場合）
if [ -f "target/x86_64-pc-windows-gnu/release/ym2151.dll" ]; then
    echo "Checking DLL dependencies..."
    x86_64-w64-mingw32-objdump -p target/x86_64-pc-windows-gnu/release/ym2151.dll | grep -i "dll" || echo "✓ No DLL dependencies (static build successful)"
fi

echo "========================================="
echo "Rust library build finished successfully!"
echo "========================================="
