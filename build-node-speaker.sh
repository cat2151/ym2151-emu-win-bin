#!/bin/bash
# Build script for node-speaker with static linking on Windows/MSYS2 mingw

set -e

echo "=========================================="
echo "Building node-speaker with static linking"
echo "=========================================="

# Set environment variables for static linking
export LDFLAGS="-static-libgcc -static-libstdc++"
export CFLAGS="-static"
export CXXFLAGS="-static"

# Install required MSYS2 packages
echo "Installing MSYS2 packages..."
pacman -S --noconfirm \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-portaudio \
    mingw-w64-x86_64-pkg-config \
    make \
    git

# Set up Node.js build environment
echo "Setting up Node.js build environment..."
export npm_config_build_from_source=true
export npm_config_runtime=node

# Clone node-speaker if not present
if [ ! -d "node-speaker" ]; then
    echo "Cloning node-speaker..."
    # Clone from the official repository
    # Note: For production use, consider pinning to a specific commit or tag
    # Example: git clone --branch v0.5.4 https://github.com/TooTallNate/node-speaker.git
    git clone https://github.com/TooTallNate/node-speaker.git
fi

cd node-speaker

# Install node-gyp globally if not present
npm list -g node-gyp || npm install -g node-gyp

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build node_modules

# Install dependencies
echo "Installing npm dependencies..."
npm install --ignore-scripts

# Configure node-gyp with static linking flags
echo "Configuring build with static linking..."
export GYP_DEFINES="component=static_library"

# Create custom binding.gyp modifications if needed
# The binding.gyp should link PortAudio statically

# Build with node-gyp
echo "Building node-speaker..."

# Try to find node directory
NODE_DIR=$(node -e "console.log(process.execPath)" | sed 's|/bin/node.*||' | sed 's|\\bin\\node.*||')
echo "Node directory: $NODE_DIR"

node-gyp configure build --release \
    --nodedir="$NODE_DIR" \
    -- -Dportaudio_use_pkg_config=true

# Verify build
if [ -f "build/Release/binding.node" ]; then
    echo "=========================================="
    echo "Build successful!"
    echo "Built library: build/Release/binding.node"
    echo "=========================================="
    
    # Copy to output directory
    mkdir -p ../output
    cp build/Release/binding.node ../output/
    
    # Copy package files
    cp package.json ../output/
    cp -r lib ../output/ 2>/dev/null || true
    
    echo "Output copied to: ../output/"
else
    echo "=========================================="
    echo "Build failed - binding.node not found"
    echo "=========================================="
    exit 1
fi
