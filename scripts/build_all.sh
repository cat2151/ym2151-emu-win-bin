#!/bin/bash
set -e

echo "========================================="
echo "Building all YM2151 Emulator CLIs"
echo "========================================="

# Rust
if [ -f "scripts/build_rust.sh" ]; then
    echo ""
    echo "Building Rust..."
    bash scripts/build_rust.sh
else
    echo "⚠ Rust build script not found"
fi

# Go
if [ -f "scripts/build_go.sh" ]; then
    echo ""
    echo "Building Go..."
    bash scripts/build_go.sh
else
    echo "⚠ Go build script not found"
fi

# Python (Windows only)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    if [ -f "scripts/build_python.sh" ]; then
        echo ""
        echo "Building Python..."
        bash scripts/build_python.sh
    else
        echo "⚠ Python build script not found"
    fi
else
    echo "⚠ Python build skipped (Windows required)"
fi

# TypeScript (Windows only)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    if [ -f "scripts/build_typescript.sh" ]; then
        echo ""
        echo "Building TypeScript..."
        bash scripts/build_typescript.sh
    else
        echo "⚠ TypeScript build script not found"
    fi
else
    echo "⚠ TypeScript build skipped (Windows required)"
fi

echo ""
echo "========================================="
echo "All builds completed!"
echo "========================================="
