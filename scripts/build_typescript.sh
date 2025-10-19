#!/bin/bash
set -e

echo "========================================="
echo "Building TypeScript/Node.js YM2151 Library for Windows"
echo "========================================="

cd src/typescript_node

# Nuked-OPMのダウンロード
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# Node.js環境でのビルド（Windows推奨）
if command -v node &> /dev/null; then
    echo "Node.js found, building Native Addon..."
    
    # 依存関係のインストール
    if [ ! -d "node_modules" ]; then
        echo "Installing dependencies..."
        npm install
    fi
    
    # Native Addonのビルド
    echo "Building Native Addon..."
    npx node-gyp rebuild
    
    # 確認
    echo "Build completed!"
    ls -lh build/Release/ym2151.node 2>/dev/null || echo "Native addon not found in expected location"
else
    echo "Node.js not found."
    echo "This build requires Node.js and node-gyp."
    echo "Please install Node.js or use GitHub Actions with windows-latest."
    exit 1
fi

echo "========================================="
echo "TypeScript/Node.js library build finished successfully!"
echo "========================================="
