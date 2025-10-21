#!/bin/bash
set -e

echo "========================================="
echo "Building all YM2151 Emulator Libraries"
echo "========================================="

# Rust
if [ -f "scripts/build_rust.sh" ]; then
    echo ""
    echo "Building Rust library..."
    bash scripts/build_rust.sh
else
    echo "⚠ Rust build script not found"
fi

# Go
if [ -f "scripts/build_go.sh" ]; then
    echo ""
    echo "Building Go library..."
    bash scripts/build_go.sh
else
    echo "⚠ Go build script not found"
fi

# Python
if [ -f "scripts/build_python.sh" ]; then
    echo ""
    echo "Building Python library..."
    bash scripts/build_python.sh
else
    echo "⚠ Python build script not found"
fi

echo ""
echo "========================================="
echo "All library builds completed!"
echo "========================================="
