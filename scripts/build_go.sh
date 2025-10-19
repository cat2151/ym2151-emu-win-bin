#!/bin/bash
set -e

echo "========================================="
echo "Building Go CLI for Windows"
echo "========================================="

cd src/go

# Nuked-OPMのダウンロード
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# 環境変数の設定
export GOOS=windows
export GOARCH=amd64
export CGO_ENABLED=1
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++

# 依存関係の取得
echo "Downloading dependencies..."
go mod download

# ビルド
echo "Building Go binary..."
go build -v \
    -ldflags "-s -w -linkmode external -extldflags '-static'" \
    -o ym2151-emu.exe

# 確認
echo "Build completed!"
ls -lh ym2151-emu.exe

# DLL依存の確認
echo "Checking DLL dependencies..."
x86_64-w64-mingw32-objdump -p ym2151-emu.exe | grep -i "dll" || echo "✓ No DLL dependencies (static build successful)"

echo "========================================="
echo "Go build finished successfully!"
echo "========================================="
