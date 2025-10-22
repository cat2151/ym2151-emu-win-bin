#!/bin/bash
set -e

echo "========================================="
echo "Building Nuked-OPM Library for Windows (Go)"
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
    x86_64-w64-mingw32-ar rcs libnukedopm.a opm.o
    rm -f opm.o
fi

# 確認
echo "Build completed!"
ls -lh libnukedopm.a

# シンボルの確認
echo "Checking symbols in library (should see official Nuked-OPM functions)..."
x86_64-w64-mingw32-nm libnukedopm.a | grep OPM | head -5

echo "========================================="
echo "Nuked-OPM library build finished successfully!"
echo "Note: Exported functions use official Nuked-OPM API (OPM_Reset, OPM_Write, OPM_Clock, etc.)"
echo "========================================="
