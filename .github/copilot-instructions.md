# Copilot Instructions for ym2151-emu-win-bin

## Repository Overview

This repository builds **official Nuked-OPM** (YM2151 emulator) library binaries for Windows, making them accessible from multiple programming languages (Rust, Go, Python). 

**Key Point**: This repository does NOT provide custom wrappers. All libraries expose the official Nuked-OPM API directly:
- Functions: `OPM_Reset()`, `OPM_Write()`, `OPM_Clock()`, `OPM_Read()`, etc.
- Structures: `opm_t`
- Signatures: Match official `opm.h` exactly

## Repository Structure

```
ym2151-emu-win-bin/
├── .github/
│   └── workflows/          # Separate workflows for each language
│       ├── build-rust.yml
│       ├── build-go.yml
│       └── build-python.yml
├── src/
│   ├── rust/              # Rust library source
│   ├── go/                # Go library source
│   └── python/            # Python library source
├── scripts/               # Build scripts for each language
│   ├── build_rust.sh
│   ├── build_go.sh
│   ├── build_python.sh
│   └── build_all.sh
├── binaries/              # Built library binaries (committed by CI)
│   ├── rust/
│   ├── go/
│   └── python/
└── docs/                  # Documentation
```

## Build Process

### Build Environment
- **Platform**: WSL2 (Ubuntu) targeting Windows
- **Compiler**: mingw-w64 for cross-compilation
- **Languages**:
  - Rust: Uses cargo with `x86_64-pc-windows-gnu` target
  - Go: Uses CGO with mingw cross-compilation
  - Python: Uses mingw to build DLLs

### Build Scripts
Each language has a dedicated build script in `scripts/`:
- `build_rust.sh` - Builds Rust static and dynamic libraries
- `build_go.sh` - Builds Go static library
- `build_python.sh` - Builds Python DLL
- `build_all.sh` - Builds all libraries sequentially

To build locally:
```bash
./scripts/build_all.sh
# Or individual languages:
./scripts/build_rust.sh
./scripts/build_go.sh
./scripts/build_python.sh
```

### Library Dependencies
The primary dependency is **Nuked-OPM** from https://github.com/nukeykt/Nuked-OPM, which is cloned into `vendor/nuked-opm` during the build process.

## GitHub Actions Workflows

Each language has an **independent** workflow that:
1. Runs daily at 00:00 UTC
2. Can be triggered manually via `workflow_dispatch`
3. Triggers on changes to language-specific files
4. Builds the library for Windows
5. Commits successful builds to `binaries/` directory

**Workflow Independence**: Each workflow is separate to ensure:
- Failure isolation (one language failing doesn't block others)
- Parallel execution capability
- Easier debugging of language-specific issues
- Partial success handling

## Output Artifacts

### Rust
- `binaries/rust/libnukedopm.a` - Static library
- `binaries/rust/nukedopm.dll` - Dynamic library

### Go
- `binaries/go/libnukedopm.a` - Static library (for use with CGO)

### Python
- `binaries/python/nukedopm.dll` - Dynamic library (for use with ctypes)

## Coding Standards

### General Principles
- **Minimal changes**: Make the smallest possible modifications
- **Official API preservation**: Never modify the Nuked-OPM API signatures
- **Static linking**: Ensure libraries don't depend on mingw runtime DLLs
- **Cross-platform builds**: All builds must work in WSL2 targeting Windows

### Language-Specific Guidelines

#### Rust
- Use `cargo` for building
- Configure static linking via `.cargo/config.toml`
- Target: `x86_64-pc-windows-gnu`
- Linker: `x86_64-w64-mingw32-gcc`

#### Go
- Use CGO for C library integration
- Set environment variables for mingw cross-compilation
- Static linking flags: `-static -static-libgcc`

#### Python
- Build DLLs using mingw directly
- Ensure exported functions are accessible via ctypes
- No Python wrapper code - DLL exposes C API directly

### Documentation
- Primary language: Japanese (日本語)
- English versions provided where appropriate
- Keep README.md and docs/ updated with any architectural changes

## Testing Approach

Currently, this repository focuses on **build verification** rather than runtime testing:
1. Build scripts verify successful compilation
2. GitHub Actions verify cross-platform builds work
3. Output files are checked for existence and basic properties
4. Runtime testing is performed in consuming projects (e.g., ym2151-emulator-examples)

When making changes:
- Ensure build scripts complete successfully
- Verify GitHub Actions workflows pass
- Check that output binaries are generated in `binaries/` directory
- Manually test with consuming projects if API changes are made

## Common Tasks

### Adding a New Language Support
1. Create `src/{language}/` directory with source
2. Create `scripts/build_{language}.sh` build script
3. Create `.github/workflows/build-{language}.yml` workflow
4. Update main README.md with new language details
5. Ensure static linking and official API preservation

### Modifying Build Process
1. Update relevant build script in `scripts/`
2. Update corresponding GitHub Actions workflow
3. Test locally in WSL2 environment
4. Verify workflow runs successfully in GitHub Actions

### Updating Nuked-OPM Version
1. Update git clone/checkout commands in build scripts
2. Test all language builds
3. Verify API compatibility is maintained
4. Update documentation if API changes

## Important Notes

- **No Custom Wrappers**: This repository provides the official Nuked-OPM API only
- **Binary Commits**: Built binaries in `binaries/` are committed by CI workflows
- **Language Independence**: Each language build is completely independent
- **Windows Target**: All outputs target Windows x86_64, built from Linux
- **Static Linking**: Libraries must be statically linked to avoid mingw runtime dependencies

## Related Repositories

- **Nuked-OPM** (upstream): https://github.com/nukeykt/Nuked-OPM
- **ym2151-emulator-examples** (consumer): https://github.com/cat2151/ym2151-emulator-examples

## Questions or Issues?

When working on issues:
1. Check existing documentation in `docs/`
2. Review relevant build scripts in `scripts/`
3. Examine GitHub Actions workflow definitions
4. Test locally before committing
5. Ensure all three language builds still work after changes
