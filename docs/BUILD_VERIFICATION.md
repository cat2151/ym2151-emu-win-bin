# Build Script Verification Guide

このドキュメントは、生成されたビルドスクリプトとビルド設定ファイルの検証方法を説明します。

## 生成されたファイル

### Rust (src/rust/)
- `Cargo.toml` - Cargoプロジェクト設定
- `build.rs` - ビルドスクリプト（Nuked-OPMのコンパイル）
- `src/lib.rs` - FFIバインディング
- `README.md` - ビルド手順とドキュメント

### Go (src/go/)
- `Makefile` - ビルド設定
- `ym2151.h` - ヘッダファイル
- `README.md` - ビルド手順とドキュメント

### Python (src/python/)
- `Makefile` - ビルド設定
- `README.md` - ビルド手順とドキュメント

### TypeScript/Node.js (src/typescript_node/)
- `package.json` - npm パッケージ設定
- `binding.gyp` - Native Addonビルド設定
- `src/ym2151_addon.cc` - Native Addon実装
- `README.md` - ビルド手順とドキュメント

## ビルドスクリプトの検証

### 構文チェック

```bash
# すべてのシェルスクリプトの構文チェック
bash -n scripts/build_rust.sh
bash -n scripts/build_go.sh
bash -n scripts/build_python.sh
bash -n scripts/build_typescript.sh
bash -n scripts/build_all.sh
```

### Makefileの検証

```bash
# Go Makefile
cd src/go && make -n

# Python Makefile
cd src/python && make -n
```

### Rust Cargo.tomlの検証

```bash
cd src/rust && cargo read-manifest
```

### Node.js設定の検証

```bash
# package.jsonの検証
cd src/typescript_node && python3 -m json.tool package.json > /dev/null

# binding.gypの検証
cd src/typescript_node && python3 -m json.tool binding.gyp > /dev/null
```

## ビルドの実行

### 前提条件

#### WSL2 (Ubuntu) での実行
```bash
# 共通
sudo apt-get update
sudo apt-get install -y mingw-w64 make

# Rust用（オプション）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add x86_64-pc-windows-gnu

# Go用（オプション）
# Go自体はビルドに不要（静的ライブラリのみ生成）

# Node.js用（TypeScriptのみ）
# Node.jsとnpmが必要
```

### ビルドの実行方法

```bash
# リポジトリのルートから

# 個別のビルド
bash scripts/build_rust.sh
bash scripts/build_go.sh
bash scripts/build_python.sh
bash scripts/build_typescript.sh

# すべてのビルド
bash scripts/build_all.sh
```

## ビルドスクリプトの動作

各ビルドスクリプトは以下を実行します：

1. **Nuked-OPMのダウンロード**
   - vendor/nuked-opmディレクトリが存在しない場合、GitHubからクローン

2. **ビルド設定の生成**（Rustのみ）
   - .cargo/config.tomlを自動生成

3. **ビルドの実行**
   - 各言語の設定ファイルに基づいてライブラリをビルド

4. **成果物の確認**
   - ビルドされたライブラリファイルの存在を確認
   - シンボルやDLL依存を検証（可能な場合）

## ディレクトリ構造

```
ym2151-emu-win-bin/
├── scripts/                    # ビルドスクリプト
│   ├── build_rust.sh
│   ├── build_go.sh
│   ├── build_python.sh
│   ├── build_typescript.sh
│   └── build_all.sh
└── src/                        # ソースコード
    ├── rust/                   # Rust用ビルド設定
    │   ├── Cargo.toml
    │   ├── build.rs
    │   ├── src/
    │   │   └── lib.rs
    │   ├── vendor/             # gitignore対象（実行時に作成）
    │   │   └── nuked-opm/
    │   └── target/             # gitignore対象（ビルド成果物）
    ├── go/                     # Go用ビルド設定
    │   ├── Makefile
    │   ├── ym2151.h
    │   ├── vendor/             # gitignore対象
    │   └── libym2151.a         # gitignore対象（ビルド成果物）
    ├── python/                 # Python用ビルド設定
    │   ├── Makefile
    │   ├── vendor/             # gitignore対象
    │   └── ym2151.dll          # gitignore対象（ビルド成果物）
    └── typescript_node/        # TypeScript/Node.js用ビルド設定
        ├── package.json
        ├── binding.gyp
        ├── src/
        │   └── ym2151_addon.cc
        ├── vendor/             # gitignore対象
        ├── node_modules/       # gitignore対象
        └── build/              # gitignore対象（ビルド成果物）
```

## トラブルシューティング

### mingw-w64が見つからない
```bash
sudo apt-get install -y mingw-w64
```

### Rustターゲットが見つからない
```bash
rustup target add x86_64-pc-windows-gnu
```

### Node.jsが見つからない（TypeScriptのみ）
TypeScript/Node.jsのビルドはWindows環境またはNode.jsがインストールされた環境が必要です。

### vendor/nuked-opmが見つからない
ビルドスクリプトが自動的にクローンします。手動でクローンする場合：
```bash
cd src/rust  # または src/go, src/python, src/typescript_node
mkdir -p vendor
git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
```

## 次のステップ

ビルドが成功したら、生成されたライブラリファイルを利用できます：
- Rust: `src/rust/target/x86_64-pc-windows-gnu/release/libym2151.a`
- Go: `src/go/libym2151.a`
- Python: `src/python/ym2151.dll`
- TypeScript: `src/typescript_node/build/Release/ym2151.node`

各言語の詳しい利用方法は、各ディレクトリのREADME.mdを参照してください。
