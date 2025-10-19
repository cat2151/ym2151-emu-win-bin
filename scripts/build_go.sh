#!/bin/bash
set -e

echo "========================================="
echo "Building Go YM2151 Library for Windows"
echo "========================================="

cd src/go

# Nuked-OPMのダウンロード
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# Makefileがある場合はmakeを実行
if [ -f "Makefile" ]; then
    echo "Building library with Makefile..."
    make
else
    # 直接コンパイル
    echo "Building library directly..."
    x86_64-w64-mingw32-gcc -c -O3 -static-libgcc vendor/nuked-opm/opm.c -o opm.o
    x86_64-w64-mingw32-ar rcs libym2151.a opm.o
    rm -f opm.o
fi

# 確認
echo "Build completed!"
ls -lh libym2151.a

# シンボルの確認
echo "Checking symbols in library..."
x86_64-w64-mingw32-nm libym2151.a | grep OPM | head -5

echo "========================================="
echo "Go library build finished successfully!"
echo "========================================="
