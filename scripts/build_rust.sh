#!/bin/bash
set -e

echo "========================================="
echo "Building Rust CLI for Windows"
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
EOF

# ビルド
echo "Building Rust binary..."
cargo build --release --target x86_64-pc-windows-gnu

# 確認
echo "Build completed!"
ls -lh target/x86_64-pc-windows-gnu/release/ym2151-emu.exe

# DLL依存の確認
echo "Checking DLL dependencies..."
x86_64-w64-mingw32-objdump -p target/x86_64-pc-windows-gnu/release/ym2151-emu.exe | grep -i "dll" || echo "✓ No DLL dependencies (static build successful)"

echo "========================================="
echo "Rust build finished successfully!"
echo "========================================="
