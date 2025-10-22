# Pre-built Binaries

This directory contains pre-built Windows binaries for the Nuked-OPM YM2151 emulator library.

All binaries are automatically built by GitHub Actions and committed to this repository, making them easily accessible for use in other projects.

## Available Libraries

### Rust Library (`rust/`)
- `libnukedopm.a` - Static library for Rust projects
- `nukedopm.dll` - Dynamic library

**API**: Official Nuked-OPM functions (OPM_Reset, OPM_Write, OPM_Clock, etc.)

### Go Library (`go/`)
- `libnukedopm.a` - Static library for use with CGO

**API**: Official Nuked-OPM functions (OPM_Reset, OPM_Write, OPM_Clock, etc.)

### Python Library (`python/`)
- `nukedopm.dll` - Dynamic library for use with ctypes

**API**: Official Nuked-OPM functions (OPM_Reset, OPM_Write, OPM_Clock, etc.)

## How to Use

### From Another Repository

You can download binaries directly from this repository:

```bash
# Download a specific binary
curl -L -o nukedopm.dll https://github.com/cat2151/ym2151-emu-win-bin/raw/main/binaries/python/nukedopm.dll

# Or clone the entire repository
git clone https://github.com/cat2151/ym2151-emu-win-bin.git
```

### As a Git Submodule

```bash
git submodule add https://github.com/cat2151/ym2151-emu-win-bin.git vendor/ym2151-binaries
```

Then reference the binaries:
- Rust: `vendor/ym2151-binaries/binaries/rust/libnukedopm.a`
- Go: `vendor/ym2151-binaries/binaries/go/libnukedopm.a`
- Python: `vendor/ym2151-binaries/binaries/python/nukedopm.dll`

## Build Information

All binaries are built using:
- **Compiler**: mingw-w64 cross-compiler
- **Static linking**: mingw runtime is statically linked (no external DLL dependencies)
- **Target**: Windows x86_64
- **CI/CD**: GitHub Actions

For build details, see the workflow files in `.github/workflows/`.

## License

See the main repository LICENSE file. The Nuked-OPM library is licensed under LGPL v2.1+.
