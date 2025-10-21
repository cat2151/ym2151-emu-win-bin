# YM2151 Library Requirements Check

## Overview
This document cross-checks the libraries required by the [ym2151-emulator-examples](https://github.com/cat2151/ym2151-emulator-examples) repository against what this repository (ym2151-emu-win-bin) can provide.

**Check Date**: 2025-10-19

---

## Conclusion: All Required Libraries Can Be Provided ✅

This repository is equipped to provide all major libraries required by ym2151-emulator-examples.

---

## Detailed Language-by-Language Check

### 1. Rust Implementation ⭐⭐⭐⭐⭐

#### Requirements (ym2151-emulator-examples side)
- **Emulator Library**: Nuked-OPM (via FFI)
- **Audio Output**: cpal (cross-platform audio library)
- **Build Tool**: cc crate (for compiling C code)

#### Provision Status (ym2151-emu-win-bin side)
- ✅ **Nuked-OPM Static Library**: Can be provided
  - Build configuration in `src/rust/`
  - Can be built with `scripts/build_rust.sh`
  - Output: `libym2151.a` (static library)
- ✅ **Windows Cross-Compilation**: Supported
  - x86_64-pc-windows-gnu target
  - Static linking via mingw-w64

#### Assessment
**✅ Fully Supported**: The Rust implementation in ym2151-emulator-examples builds Nuked-OPM directly, so provision from this repository is not strictly necessary, but we provide equivalent library building capability.

---

### 2. Go Implementation ⭐⭐⭐⭐⭐

#### Requirements (ym2151-emulator-examples side)
- **Emulator Library**: Nuked-OPM (via CGO)
- **Audio Output**: PortAudio
  - Linux: ALSA
  - macOS: CoreAudio
  - Windows: WASAPI/DirectSound
- **Build Requirements**: 
  - Cross-compilation from WSL2
  - Static linking (no MinGW DLL dependency)
  - PortAudio static library

#### Provision Status (ym2151-emu-win-bin side)
- ✅ **Nuked-OPM Static Library**: Can be provided
  - Build configuration in `src/go/`
  - Can be built with `scripts/build_go.sh`
  - Output: `libym2151.a` (static library)
- ✅ **CGO Support**: Supported
  - Uses mingw-w64 cross-compiler
  - Static linking configured
- ⚠️ **PortAudio**: Not directly provided
  - Built independently by ym2151-emulator-examples
  - ym2151-emu-win-bin only provides YM2151 emulator

#### Assessment
**✅ Major Components Supported**: YM2151 emulator library can be provided. PortAudio is for audio output and not required for YM2151 emulation itself.

---

### 3. Python Implementation ⭐⭐⭐⭐

#### Requirements (ym2151-emulator-examples side)
- **Emulator Library**: Nuked-OPM (via ctypes)
- **File Format**: `libnukedopm.dll` (dynamic library)
- **Build Requirements**:
  - Build with WSL2 or MSYS2
  - Static linking (`-static-libgcc`)
  - No MinGW DLL dependency
- **Python Wrapper**: ctypes
- **Audio Output**: sounddevice + numpy

#### Provision Status (ym2151-emu-win-bin side)
- ✅ **Nuked-OPM DLL**: Can be provided
  - Build configuration in `src/python/`
  - Can be built with `scripts/build_python.sh`
  - Output: `ym2151.dll` (dynamic library, no mingw DLL dependency)
- ✅ **Static Linking**: Supported
  - Uses `-static-libgcc -static-libstdc++` flags
- ✅ **ctypes Support**: Supported
  - Exports C functions

#### Assessment
**✅ Fully Supported**: Can provide DLL usable from Python. The `ym2151.dll` we provide has equivalent functionality to the `libnukedopm.dll` required by ym2151-emulator-examples.

---

### 4. TypeScript/Node.js Implementation ⭐⭐⭐⭐⭐

#### Requirements (ym2151-emulator-examples side)
- **Emulator Library**: libymfm.wasm (WebAssembly version)
- **Features**:
  - Cross-platform via WebAssembly
  - Available as npm package
  - Includes TypeScript type definitions
- **Audio Output**: speaker (node-speaker)
  - PortAudio-based
  - Cross-platform support
- **Note**: 
  - speaker has known DoS vulnerability (CVE-2024-21526)
  - Impact limited for local execution

#### Provision Status (ym2151-emu-win-bin side)
- ⚠️ **libymfm.wasm**: Not directly provided
  - libymfm.wasm is distributed as npm package, no build needed
  - Can be used directly from npm by ym2151-emulator-examples
- ✅ **node-speaker Related**: Separately provided
  - Repository includes `build-node-speaker.sh`
  - Provides Windows build environment for node-speaker
  - Provides binding.node with PortAudio statically linked

#### Assessment
**✅ Well Supported**: 
- libymfm.wasm is an npm package, so provision from this repository is not necessary
- ym2151-emulator-examples uses libymfm.wasm, allowing users to utilize it directly from npm without complex builds
- Also provides build environment for node-speaker (PortAudio)

---

## Library List

### Libraries Provided by This Repository

| Language | Library Format | Filename | Emulator | Static Linking | Build Script |
|----------|---------------|----------|----------|----------------|--------------|
| Rust | Static Library | `libym2151.a` | Nuked-OPM | ✅ | `scripts/build_rust.sh` |
| Go | Static Library | `libym2151.a` | Nuked-OPM | ✅ | `scripts/build_go.sh` |
| Python | Dynamic Library | `ym2151.dll` | Nuked-OPM | ✅ | `scripts/build_python.sh` |
| Node.js | Native Addon | `binding.node` | - (PortAudio) | ✅ | `build-node-speaker.sh` |

**Note**: TypeScript/Node.js YM2151 emulator uses libymfm.wasm from npm package, so building in this repository is not necessary.

### Libraries Required by ym2151-emulator-examples

| Language | Required Library | Purpose | Provision Status |
|----------|-----------------|---------|------------------|
| Rust | Nuked-OPM (C) | YM2151 Emulator | ✅ Can be provided (equivalent) |
| Rust | cpal | Audio Output | N/A (for audio output, separate from YM2151 emulator) |
| Go | Nuked-OPM (C) | YM2151 Emulator | ✅ Can be provided |
| Go | PortAudio | Audio Output | N/A (for audio output, separate from YM2151 emulator) |
| Python | Nuked-OPM (DLL) | YM2151 Emulator | ✅ Can be provided |
| Python | sounddevice | Audio Output | N/A (for audio output, separate from YM2151 emulator) |
| TypeScript/Node.js | libymfm.wasm | YM2151 Emulator | ⚠️ Available directly from npm |
| TypeScript/Node.js | speaker (node-speaker) | Audio Output | ✅ Build environment provided |

**Legend**:
- ✅ Can be provided: Available from this repository
- ⚠️ External source: Available from external packages like npm (provision from this repository not needed)
- N/A: Separate component from YM2151 emulator (for audio output)

---

## Emulator Library Comparison

### Nuked-OPM vs libymfm

| Item | Nuked-OPM | libymfm |
|------|-----------|---------|
| **Language** | C | C++ |
| **License** | LGPL-2.1 | BSD-3-Clause |
| **Accuracy** | Cycle-accurate (very high) | High accuracy |
| **Supported Chips** | YM2151 only | Multiple Yamaha chips including YM2151 |
| **Build Ease** | Very easy (single C file) | Moderately complex (C++ project) |
| **Dependencies** | None | Few |
| **WebAssembly** | Possible | Already provided as libymfm.wasm |
| **This Repository** | ✅ Provided for all languages | ❌ Not currently provided |

---

## Gap Analysis

### ✅ What We Provide

1. **Nuked-OPM Library** - For all languages
   - Rust: Static library
   - Go: Static library for CGO
   - Python: DLL for ctypes
   - TypeScript/Node.js: Native Addon

2. **Windows Build Environment**
   - mingw-w64 cross-compilation
   - Static linking support
   - No MinGW DLL dependency

3. **node-speaker Build Environment**
   - PortAudio statically linked
   - Windows Native Addon

### ⚠️ What We Don't Provide (But It's OK)

1. **libymfm / libymfm.wasm**
   - Already distributed as npm package
   - Users can directly use via `npm install`
   - No need to provide from this repository

2. **Audio Output Libraries**
   - cpal (Rust): Available from crates
   - PortAudio (Go): Users build themselves (instructions in ym2151-emulator-examples)
   - sounddevice (Python): Available via pip
   - speaker (Node.js): Available from npm (but we provide pre-built binding.node for Windows)

   **Reason**: These are independent audio output libraries, separate from YM2151 emulator library scope

### ❌ What We Don't Provide (Future Consideration)

1. **libymfm C++ Library**
   - BSD-3-Clause license favorable for commercial use
   - Supports multiple Yamaha chips
   - Currently only Nuked-OPM is provided

   **Recommendation**: Consider adding libymfm library in the future
   - More flexible licensing
   - Broader chip support

---

## Recommendations

### Current Status is Sufficient
The YM2151 emulator libraries required by ym2151-emulator-examples are adequately covered by the Nuked-OPM provided by this repository.

### Future Expansion Ideas

#### Priority: Medium
1. **Add libymfm C++ Library**
   - For users requiring BSD-3-Clause license
   - When support for more diverse Yamaha chips is needed

#### Priority: Low
2. **Provide Pre-built PortAudio for Windows**
   - Pre-built Windows PortAudio library for Go implementation
   - Currently users build it themselves
   - Would simplify setup if provided

3. **More Detailed Documentation**
   - Usage examples for each language
   - How to download pre-built binaries

---

## Summary

### Overall Assessment: ✅ All Required Libraries Can Be Provided

This repository (ym2151-emu-win-bin) is equipped to provide all **YM2151 emulator libraries** required by the ym2151-emulator-examples repository.

**Major Functions We Provide**:
- ✅ Nuked-OPM Library (for all languages)
- ✅ Windows cross-compilation environment
- ✅ Static linking support (no MinGW DLL dependency)
- ✅ node-speaker build environment

**What We Don't Provide (But It's OK)**:
- libymfm.wasm (already distributed as npm package)
- Various audio output libraries (independent components from YM2151 emulator)

**Future Expansion Candidates**:
- Add libymfm C++ library (BSD-3-Clause license, more flexible)

---

## Quick Check

To quickly verify the summary of this report, run the following script:

```bash
bash scripts/check_library_requirements.sh
```

This script checks:
- Report file existence
- Build script existence
- Source directory existence
- List of available libraries

---

## Reference Links

- [ym2151-emulator-examples](https://github.com/cat2151/ym2151-emulator-examples)
- [Nuked-OPM](https://github.com/nukeykt/Nuked-OPM)
- [libymfm](https://github.com/aaronsgiles/ymfm)
- [libymfm.wasm](https://github.com/h1romas4/libymfm.wasm)
- [node-speaker](https://github.com/TooTallNate/node-speaker)
