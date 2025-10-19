#!/bin/bash
set -e

echo "========================================="
echo "Building Python CLI for Windows"
echo "========================================="

cd src/python

# Nuked-OPMのビルド（DLL作成）
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# Windows環境の場合
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "Building on Windows..."
    
    # Nuked-OPMのDLLビルド（必要な場合）
    # gcc -shared -o ym2151/lib/nuked_opm.dll -static -static-libgcc -O3 vendor/nuked-opm/opm.c
    
    # PyInstallerでビルド
    echo "Building Python binary with PyInstaller..."
    pyinstaller --onefile \
        --add-data "ym2151/lib/nuked_opm.dll;ym2151/lib" \
        --name ym2151-emu \
        main.py
else
    echo "Cross-compilation from Linux is not supported for Python."
    echo "Please use Windows environment or GitHub Actions with windows-latest."
    exit 1
fi

# 確認
echo "Build completed!"
ls -lh dist/ym2151-emu.exe

echo "========================================="
echo "Python build finished successfully!"
echo "========================================="
