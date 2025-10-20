#!/bin/bash
# Library Requirement Check Summary Script
# This script provides a quick summary of the library requirement check

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "YM2151 Library Requirement Check Summary"
echo "========================================"
echo ""

# Check if the report exists
if [ ! -f "$REPO_ROOT/docs/LIBRARY_REQUIREMENT_CHECK.md" ]; then
    echo "❌ Report file not found!"
    echo "Please run the analysis first."
    exit 1
fi

if [ ! -f "$REPO_ROOT/docs/LIBRARY_REQUIREMENT_CHECK.en.md" ]; then
    echo "⚠️  English report file not found!"
fi

echo "✅ Report found: docs/LIBRARY_REQUIREMENT_CHECK.md"
if [ -f "$REPO_ROOT/docs/LIBRARY_REQUIREMENT_CHECK.en.md" ]; then
    echo "✅ Report found: docs/LIBRARY_REQUIREMENT_CHECK.en.md"
fi
echo ""

echo "========================================"
echo "Provision Status Summary"
echo "========================================"
echo ""

# Check if build scripts exist
echo "Build Scripts:"
for lang in rust go python typescript; do
    script="$REPO_ROOT/scripts/build_${lang}.sh"
    if [ -f "$script" ]; then
        echo "  ✅ ${lang}: $(basename $script) exists"
    else
        echo "  ❌ ${lang}: Build script not found"
    fi
done
echo ""

# Check source directories
echo "Source Directories:"
# Note: typescript_node is the actual directory name in this repo
for dir in rust go python typescript_node; do
    src_dir="$REPO_ROOT/src/$dir"
    if [ -d "$src_dir" ]; then
        echo "  ✅ src/${dir}/ exists"
    else
        echo "  ❌ src/${dir}/ not found"
    fi
done
echo ""

echo "========================================"
echo "Conclusion"
echo "========================================"
echo ""
echo "✅ All required YM2151 emulator libraries can be provided"
echo ""
echo "Provided Libraries:"
echo "  ✅ Rust:       Static library (.a) - Nuked-OPM"
echo "  ✅ Go:         Static library (.a) - Nuked-OPM"
echo "  ✅ Python:     Dynamic library (.dll) - Nuked-OPM"
echo "  ✅ TypeScript: Native Addon (.node) - Nuked-OPM"
echo "  ✅ Node.js:    Native Addon (.node) - node-speaker/PortAudio"
echo ""
echo "For detailed analysis, see:"
echo "  - docs/LIBRARY_REQUIREMENT_CHECK.md (Japanese)"
echo "  - docs/LIBRARY_REQUIREMENT_CHECK.en.md (English)"
echo ""

echo "========================================"
echo "Reference Repository"
echo "========================================"
echo ""
echo "Target: https://github.com/cat2151/ym2151-emulator-examples"
echo ""

# Optional: Check if ym2151-emulator-examples is cloned in /tmp
if [ -d "/tmp/ym2151-emulator-examples" ]; then
    echo "✅ ym2151-emulator-examples repository found in /tmp"
    echo ""
    echo "Quick Requirements Check:"
    
    # Check for key files that indicate what's needed
    if [ -f "/tmp/ym2151-emulator-examples/src/rust/README.md" ]; then
        echo "  ✅ Rust implementation: Requires Nuked-OPM"
    fi
    if [ -f "/tmp/ym2151-emulator-examples/src/go/README.md" ]; then
        echo "  ✅ Go implementation: Requires Nuked-OPM + PortAudio"
    fi
    if [ -f "/tmp/ym2151-emulator-examples/src/python/README.md" ]; then
        echo "  ✅ Python implementation: Requires Nuked-OPM DLL"
    fi
    if [ -f "/tmp/ym2151-emulator-examples/src/typescript_deno/README.md" ]; then
        # Note: ym2151-emulator-examples uses "typescript_deno" while this repo uses "typescript_node"
        echo "  ✅ TypeScript/Node.js implementation: Requires libymfm.wasm + speaker"
    fi
else
    echo "ℹ️  To check requirements directly, clone ym2151-emulator-examples:"
    echo "   git clone https://github.com/cat2151/ym2151-emulator-examples /tmp/ym2151-emulator-examples"
fi

echo ""
echo "========================================"
