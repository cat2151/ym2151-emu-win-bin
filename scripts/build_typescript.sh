#!/bin/bash
set -e

echo "========================================="
echo "Building TypeScript/Node.js CLI for Windows"
echo "========================================="

cd src/typescript_node

# Nuked-OPMのダウンロード
if [ ! -d "native/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p native
    git clone https://github.com/nukeykt/Nuked-OPM.git native/nuked-opm
fi

# 依存関係のインストール
echo "Installing dependencies..."
npm install

# TypeScriptのビルド
echo "Compiling TypeScript..."
npm run build

# Native Addonのビルド
echo "Building native addon..."
npm run build:addon || echo "Native addon build step (run separately if needed)"

# pkgでパッケージング
echo "Packaging with pkg..."
npm run package

# 確認
echo "Build completed!"
ls -lh ym2151-emu.exe

echo "========================================="
echo "TypeScript build finished successfully!"
echo "========================================="
