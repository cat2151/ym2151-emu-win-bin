#!/bin/bash
set -e

echo "========================================="
echo "Building Nuked-OPM Library for Windows (Python)"
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
    x86_64-w64-mingw32-gcc -shared -o nukedopm.dll \
        -static-libgcc -static-libstdc++ \
        -O3 \
        vendor/nuked-opm/opm.c
    # Create legacy name for backward compatibility
    cp nukedopm.dll ym2151.dll
fi

# 確認
echo "Build completed!"
ls -lh nukedopm.dll ym2151.dll 2>/dev/null || ls -lh nukedopm.dll

# DLL依存の確認
echo "Checking DLL dependencies..."
x86_64-w64-mingw32-objdump -p nukedopm.dll | grep -i "dll" || echo "✓ No mingw DLL dependencies (static build successful)"

echo "========================================="
echo "Nuked-OPM library build finished successfully!"
echo "Note: Exported functions use official Nuked-OPM API (OPM_Reset, OPM_Write, OPM_Clock, etc.)"
echo "Primary: nukedopm.dll, Legacy: ym2151.dll (for backward compatibility)"
echo "========================================="
