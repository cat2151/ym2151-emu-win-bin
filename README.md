# ym2151-emu-win-bin

Windows向けYM2151エミュレータライブラリバイナリのビルドリポジトリ

## 概要

このリポジトリは、Yamaha YM2151 (OPM) サウンドチップのエミュレータライブラリを、複数のプログラミング言語（Rust、Go、Python、TypeScript/Node.js）から利用可能な形式でビルドし、Windows向けのライブラリバイナリを生成します。

すべてのライブラリバイナリは以下の要件を満たします：
- **静的リンク対応**: mingw DLLに依存しない `.a` (static library) または `.dll` (dynamic library) を生成
- **言語バインディング対応**: Rust、Go、Python、TypeScript/Node.jsから利用可能
- **クロスプラットフォームビルド**: WSL2からWindows向けにビルド可能

## ディレクトリ構造

```
ym2151-emu-win-bin/
├── docs/                           # ドキュメント
│   ├── libraries.md               # 使用ライブラリのリスト
│   ├── implementation_plan_rust.md
│   ├── implementation_plan_go.md
│   ├── implementation_plan_python.md
│   ├── implementation_plan_typescript.md
│   └── github_actions_plan.md     # GitHub Actions実装計画
├── src/
│   ├── rust/                      # Rust用ライブラリビルド
│   ├── go/                        # Go用ライブラリビルド
│   ├── python/                    # Python用ライブラリビルド
│   └── typescript_node/           # TypeScript/Node.js用ライブラリビルド
├── scripts/                       # ビルドスクリプト
│   ├── build_rust.sh
│   ├── build_go.sh
│   ├── build_python.sh
│   ├── build_typescript.sh
│   └── build_all.sh
├── binaries/                      # ビルド済みライブラリバイナリ（GitHub Actions）
│   ├── rust/
│   ├── go/
│   ├── python/
│   └── typescript/
└── .github/workflows/
    └── daily-build.yml           # 毎日のビルドワークフロー
```

## 使用ライブラリ

### YM2151エミュレータライブラリ

このリポジトリでビルドするライブラリ：

1. **Nuked-OPM** (推奨)
   - リポジトリ: https://github.com/nukeykt/Nuked-OPM
   - サイクル精度の高いC実装
   - 各言語から利用可能な形式でビルド

2. **libymfm** (代替案)
   - リポジトリ: https://github.com/aaronsgiles/ymfm
   - モダンなC++実装

### ビルド成果物

各言語向けに以下の形式のライブラリバイナリを生成：

- **Rust**: `.a` (static library) または `.lib` (Windows static library)
- **Go**: `.a` (static library) - CGO経由で利用
- **Python**: `.dll` (dynamic library) - ctypes経由で利用
- **TypeScript/Node.js**: `.dll` または `.node` (Native Addon)

詳細は [docs/libraries.md](docs/libraries.md) を参照。

## ビルド方法

### WSL2でのビルド

各言語のライブラリビルドスクリプトを実行：

```bash
# すべてビルド
./scripts/build_all.sh

# 個別にビルド
./scripts/build_rust.sh
./scripts/build_go.sh
./scripts/build_python.sh
./scripts/build_typescript.sh
```

### 前提条件

#### WSL2 (Ubuntu)

```bash
# 共通
sudo apt-get update
sudo apt-get install -y mingw-w64

# Rust用（オプション：Rustからも利用する場合）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add x86_64-pc-windows-gnu

# Go用（オプション：Goからも利用する場合）
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

## GitHub Actions

毎日午前0時（UTC）に自動的にすべてのライブラリをビルドし、`binaries/` ディレクトリにコミットします。

ワークフローの詳細は [docs/github_actions_plan.md](docs/github_actions_plan.md) を参照。

### 手動実行

GitHub Actionsページから「Daily Windows Binary Build」ワークフローを手動で実行できます。

## 実装計画

各言語の詳細なビルド計画は以下のドキュメントを参照：

- [Rust用ライブラリビルド計画](docs/implementation_plan_rust.md)
- [Go用ライブラリビルド計画](docs/implementation_plan_go.md)
- [Python用ライブラリビルド計画](docs/implementation_plan_python.md)
- [TypeScript/Node.js用ライブラリビルド計画](docs/implementation_plan_typescript.md)
- [GitHub Actions実装計画](docs/github_actions_plan.md)

## ライブラリの使用方法

ビルドされたライブラリは各言語から以下のように利用できます：

### Rust
```rust
// 静的ライブラリとしてリンク
// Cargo.tomlで指定
```

### Go
```go
// CGO経由で利用
// #cgo LDFLAGS: -L./path/to/lib -lym2151
```

### Python
```python
# ctypes経由でDLLをロード
import ctypes
lib = ctypes.CDLL('./binaries/python/ym2151.dll')
```

### TypeScript/Node.js
```typescript
// Native Addonまたはdllとしてロード
const ym2151 = require('./binaries/typescript/ym2151.node');
```

## 開発ステータス

- [x] リポジトリ初期設定
- [x] YM2151ライブラリリストの作成
- [x] 各言語のビルド計画書作成
- [x] GitHub Actions実装計画書作成
- [x] ビルドスクリプトの作成
- [x] GitHub Actionsワークフローの作成
- [ ] Rust用ライブラリビルド
- [ ] Go用ライブラリビルド
- [ ] Python用ライブラリビルド
- [ ] TypeScript/Node.js用ライブラリビルド

## ライセンス

このリポジトリのコードはLICENSEファイルに従います。

使用しているライブラリのライセンス：
- Nuked-OPM: LGPL v2.1+
- libymfm: BSD-3-Clause
- 各音声出力ライブラリ: 各ライブラリのライセンスに従う

## 参考

- [YM2151 emulator examples](https://github.com/cat2151/ym2151-emulator-examples)
- [Nuked-OPM](https://github.com/nukeykt/Nuked-OPM)
- [libymfm](https://github.com/aaronsgiles/ymfm)
