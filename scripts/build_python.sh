#!/bin/bash
set -e

echo "========================================="
echo "Building Python YM2151 Library for Windows"
echo "========================================="

cd src/python

# Nuked-OPMのダウンロード
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# Makefileがある場合はmakeを実行
if [ -f "Makefile" ]; then
    echo "Building DLL with Makefile..."
    make
else
    # 直接コンパイル
    echo "Building DLL directly..."
    x86_64-w64-mingw32-gcc -shared -o ym2151.dll \
        -static-libgcc -static-libstdc++ \
        -O3 \
        vendor/nuked-opm/opm.c
fi

# 確認
echo "Build completed!"
ls -lh ym2151.dll

# DLL依存の確認
echo "Checking DLL dependencies..."
x86_64-w64-mingw32-objdump -p ym2151.dll | grep -i "dll" || echo "✓ No mingw DLL dependencies (static build successful)"

echo "========================================="
echo "Python library build finished successfully!"
echo "========================================="
