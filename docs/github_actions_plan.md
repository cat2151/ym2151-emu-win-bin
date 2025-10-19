# GitHub Actions実装計画書

## 概要

毎日自動的にすべての言語（Rust、Go、Python、TypeScript/Node.js）のWindows向けバイナリをビルドし、
成果物をリポジトリにコミットするGitHub Actionsワークフローを作成します。

## ワークフロー設計

### 1. トリガー設定

- **スケジュール**: 毎日午前0時（UTC）に実行
- **手動トリガー**: `workflow_dispatch`で手動実行可能
- **プッシュトリガー**: ビルドスクリプトの変更時に実行

### 2. ジョブ構成

各言語ごとに独立したジョブを作成し、並列実行します：

1. **build-rust**: Rust CLIのビルド
2. **build-go**: Go CLIのビルド
3. **build-python**: Python CLIのビルド
4. **build-typescript**: TypeScript/Node.js CLIのビルド
5. **commit-binaries**: ビルドしたバイナリをコミット

## ワークフローファイル

### .github/workflows/daily-build.yml

```yaml
name: Daily Windows Binary Build

on:
  schedule:
    # 毎日UTC 00:00に実行（JST 09:00）
    - cron: '0 0 * * *'
  
  # 手動実行を許可
  workflow_dispatch:
  
  # ビルドスクリプトの変更時にも実行
  push:
    paths:
      - 'scripts/**'
      - '.github/workflows/daily-build.yml'

jobs:
  build-rust:
    name: Build Rust CLI
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y mingw-w64
      
      - name: Setup Rust
        uses: actions-rust-lang/setup-rust-toolchain@v1
        with:
          toolchain: stable
          target: x86_64-pc-windows-gnu
      
      - name: Build Rust binary
        run: |
          chmod +x scripts/build_rust.sh
          ./scripts/build_rust.sh
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ym2151-emu-rust
          path: src/rust/target/x86_64-pc-windows-gnu/release/ym2151-emu.exe
          retention-days: 30
  
  build-go:
    name: Build Go CLI
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y mingw-w64
      
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.21'
      
      - name: Build Go binary
        run: |
          chmod +x scripts/build_go.sh
          ./scripts/build_go.sh
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ym2151-emu-go
          path: src/go/ym2151-emu.exe
          retention-days: 30
  
  build-python:
    name: Build Python CLI
    runs-on: windows-latest  # PyInstallerはネイティブ環境が推奨
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r src/python/requirements.txt
          pip install pyinstaller
      
      - name: Build Python binary
        shell: bash
        run: |
          chmod +x scripts/build_python.sh
          ./scripts/build_python.sh
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ym2151-emu-python
          path: src/python/dist/ym2151-emu.exe
          retention-days: 30
  
  build-typescript:
    name: Build TypeScript/Node.js CLI
    runs-on: windows-latest  # Native Addonのビルドにはネイティブ環境が必要
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install dependencies
        working-directory: src/typescript_node
        run: npm install
      
      - name: Build TypeScript binary
        shell: bash
        working-directory: src/typescript_node
        run: |
          npm run build
          npm run package
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: ym2151-emu-typescript
          path: src/typescript_node/ym2151-emu.exe
          retention-days: 30
  
  commit-binaries:
    name: Commit Built Binaries
    runs-on: ubuntu-latest
    needs: [build-rust, build-go, build-python, build-typescript]
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Create binaries directory
        run: mkdir -p binaries
      
      - name: Download Rust artifact
        uses: actions/download-artifact@v4
        with:
          name: ym2151-emu-rust
          path: binaries/rust/
      
      - name: Download Go artifact
        uses: actions/download-artifact@v4
        with:
          name: ym2151-emu-go
          path: binaries/go/
      
      - name: Download Python artifact
        uses: actions/download-artifact@v4
        with:
          name: ym2151-emu-python
          path: binaries/python/
      
      - name: Download TypeScript artifact
        uses: actions/download-artifact@v4
        with:
          name: ym2151-emu-typescript
          path: binaries/typescript/
      
      - name: Commit and push binaries
        run: |
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git config --local user.name "github-actions[bot]"
          git add binaries/
          git diff --staged --quiet || git commit -m "🤖 Daily build: Update Windows binaries $(date +'%Y-%m-%d')"
          git push
```

## ビルドスクリプト

各言語用のビルドスクリプトを作成します。

### scripts/build_rust.sh

```bash
#!/bin/bash
set -e

echo "========================================="
echo "Building Rust CLI for Windows"
echo "========================================="

cd src/rust

# Nuked-OPMのダウンロード（git submoduleまたは直接ダウンロード）
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# .cargo/config.tomlの作成（静的リンク設定）
mkdir -p .cargo
cat > .cargo/config.toml << 'EOF'
[target.x86_64-pc-windows-gnu]
rustflags = ["-C", "target-feature=+crt-static"]
EOF

# ビルド
echo "Building Rust binary..."
cargo build --release --target x86_64-pc-windows-gnu

# 確認
echo "Build completed!"
ls -lh target/x86_64-pc-windows-gnu/release/ym2151-emu.exe

# DLL依存の確認
echo "Checking DLL dependencies..."
x86_64-w64-mingw32-objdump -p target/x86_64-pc-windows-gnu/release/ym2151-emu.exe | grep -i "dll" || echo "✓ No DLL dependencies (static build successful)"

echo "========================================="
echo "Rust build finished successfully!"
echo "========================================="
```

### scripts/build_go.sh

```bash
#!/bin/bash
set -e

echo "========================================="
echo "Building Go CLI for Windows"
echo "========================================="

cd src/go

# Nuked-OPMのダウンロード
if [ ! -d "vendor/nuked-opm" ]; then
    echo "Downloading Nuked-OPM..."
    mkdir -p vendor
    git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
fi

# 環境変数の設定
export GOOS=windows
export GOARCH=amd64
export CGO_ENABLED=1
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++

# 依存関係の取得
echo "Downloading dependencies..."
go mod download

# ビルド
echo "Building Go binary..."
go build -v \
    -ldflags "-s -w -linkmode external -extldflags '-static'" \
    -o ym2151-emu.exe

# 確認
echo "Build completed!"
ls -lh ym2151-emu.exe

# DLL依存の確認
echo "Checking DLL dependencies..."
x86_64-w64-mingw32-objdump -p ym2151-emu.exe | grep -i "dll" || echo "✓ No DLL dependencies (static build successful)"

echo "========================================="
echo "Go build finished successfully!"
echo "========================================="
```

### scripts/build_python.sh

```bash
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
```

### scripts/build_all.sh

すべての言語のビルドを一括実行するスクリプト：

```bash
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
```

## 実装優先度

1. **高**: 基本的なワークフロー構造
2. **高**: Rustビルドジョブとスクリプト
3. **高**: Goビルドジョブとスクリプト
4. **中**: Pythonビルドジョブとスクリプト
5. **中**: TypeScriptビルドジョブとスクリプト
6. **中**: バイナリコミットジョブ
7. **低**: エラーハンドリングと通知

## 技術的課題と対策

### 課題1: GitHub Actionsの実行時間制限
- **対策**: 各ジョブを並列実行し、全体の実行時間を短縮

### 課題2: バイナリのコミット容量
- **対策**: Git LFS を使用するか、定期的に古いバイナリを削除

### 課題3: クロスコンパイルの複雑さ
- **対策**: PythonとTypeScriptはWindows環境でビルド

## セキュリティ考慮事項

1. **GITHUB_TOKEN**: デフォルトのトークンを使用（追加設定不要）
2. **依存関係のキャッシュ**: `actions/cache`を使用してビルド時間を短縮
3. **アーティファクトの保持期間**: 30日間に制限

## 改善案

### フェーズ2: 追加機能

1. **リリース自動作成**: タグプッシュ時にGitHub Releaseを作成
2. **テスト実行**: ビルド前にユニットテストを実行
3. **バイナリ検証**: ビルド後にDLL依存をチェック
4. **通知機能**: ビルド失敗時にIssueを作成

### 改善版ワークフロー（オプション）

```yaml
# 追加のジョブ例

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Rust tests
        run: |
          cd src/rust
          cargo test
      
      - name: Run Go tests
        run: |
          cd src/go
          go test ./...

  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    needs: commit-binaries
    if: startsWith(github.ref, 'refs/tags/')
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: binaries/**/*.exe
          generate_release_notes: true
```

## 参考資料

- GitHub Actions Documentation: https://docs.github.com/en/actions
- actions/upload-artifact: https://github.com/actions/upload-artifact
- actions/download-artifact: https://github.com/actions/download-artifact
- Cross-compilation guide: https://github.com/cross-rs/cross
