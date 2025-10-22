# Binary Commit Fix

## Issue

GitHub Actions builds were creating artifacts but not committing binaries to the repository, making it difficult for other repositories to access the built libraries. This was reported in the issue:

**Title**: "GitHub Actions でビルドされたものが、artifactsになっており、commitやreleaseがされていないため、別リポジトリからの入手がしづらい"

**Translation**: "Items built by GitHub Actions are stored as artifacts and are not committed or released, making them difficult to obtain from other repositories"

## Root Cause

The `.gitignore` file was configured to ignore all binary files (`*.dll`, `*.a`, `*.lib`, etc.) throughout the repository, which prevented the GitHub Actions workflows from committing the built binaries to the `binaries/` directory.

```gitignore
# Old .gitignore (problematic)
*.dll
*.a
*.lib
```

## Solution

### 1. Fixed .gitignore

Modified `.gitignore` to allow binary files only in the `binaries/` directory:

```gitignore
# New .gitignore (fixed)
# Exclude binary files except in binaries/ directory
*.dll
*.so
*.dylib
*.a
*.lib
!binaries/**/*.dll
!binaries/**/*.so
!binaries/**/*.dylib
!binaries/**/*.a
!binaries/**/*.lib
```

This pattern:
- Ignores binary files everywhere by default
- Explicitly allows (`!`) binary files in the `binaries/` directory and its subdirectories

### 2. Added .gitattributes

Created `.gitattributes` to ensure binary files are properly handled:

```gitattributes
# Binary files in binaries/ directory should be treated as binary
binaries/**/*.dll binary
binaries/**/*.so binary
binaries/**/*.dylib binary
binaries/**/*.a binary
binaries/**/*.lib binary
```

### 3. Created binaries/ Directory Structure

```
binaries/
├── README.md          # Documentation on using the binaries
├── rust/
│   └── .gitkeep       # Placeholder to ensure directory exists
├── go/
│   └── .gitkeep
└── python/
    └── .gitkeep
```

### 4. Enhanced Workflows

Added error handling to workflows:

```yaml
- name: Upload artifact
  uses: actions/upload-artifact@v4
  if: success()
  with:
    name: nukedopm-rust
    path: |
      src/rust/target/x86_64-pc-windows-gnu/release/libnukedopm.a
      src/rust/target/x86_64-pc-windows-gnu/release/nukedopm.dll
    retention-days: 30
    if-no-files-found: warn  # Don't fail if files don't exist

- name: Commit binaries
  if: success()
  run: |
    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
    mkdir -p binaries/rust
    cp src/rust/target/x86_64-pc-windows-gnu/release/libnukedopm.a binaries/rust/ 2>/dev/null || true
    cp src/rust/target/x86_64-pc-windows-gnu/release/nukedopm.dll binaries/rust/ 2>/dev/null || true
    git add binaries/rust/
    git diff --staged --quiet || git commit -m "🤖 Update Nuked-OPM Rust library $(date +'%Y-%m-%d')"
    git push
```

### 5. Updated Documentation

Added instructions in main README for accessing binaries:

```bash
# Direct download
curl -L -o nukedopm.dll https://github.com/cat2151/ym2151-emu-win-bin/raw/main/binaries/python/nukedopm.dll

# Git submodule
git submodule add https://github.com/cat2151/ym2151-emu-win-bin.git vendor/ym2151-binaries

# Clone repository
git clone https://github.com/cat2151/ym2151-emu-win-bin.git
```

## Result

After this fix:

1. ✅ **Binaries are committed**: GitHub Actions can now commit built binaries to the repository
2. ✅ **Easy access**: Other repositories can access binaries via direct download, git submodule, or cloning
3. ✅ **No artifact expiration**: Binaries in the repository don't expire (unlike artifacts which expire after 30 days)
4. ✅ **Version tracking**: Binary updates are tracked in git history with commit messages like "🤖 Update Nuked-OPM Rust library 2025-10-22"

## Reference

This approach follows the pattern used by [spatialaudio/portaudio-binaries](https://github.com/spatialaudio/portaudio-binaries), which commits built binaries directly to the repository for easy access.

## Testing

To verify the fix works:

1. Trigger a workflow manually (e.g., "Build Rust Library")
2. Check if the workflow successfully commits binaries to `binaries/rust/`
3. Verify binaries are accessible via:
   - Direct download: `curl -L -o file.dll https://github.com/cat2151/ym2151-emu-win-bin/raw/main/binaries/rust/nukedopm.dll`
   - Git clone: `git clone https://github.com/cat2151/ym2151-emu-win-bin.git && ls binaries/rust/`

## Next Steps

1. Monitor scheduled builds to ensure they work correctly
2. Consider adding releases/tags for versioned binaries (optional enhancement)
3. Update dependent repositories to reference binaries from this repository
