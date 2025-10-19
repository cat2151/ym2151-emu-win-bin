# ym2151-emu-win-bin

Windows向けYM2151エミュレータCLIバイナリのビルドリポジトリ

## 概要

このリポジトリは、Yamaha YM2151 (OPM) サウンドチップのエミュレータを、複数のプログラミング言語（Rust、Go、Python、TypeScript/Node.js）でビルドし、Windows向けのスタンドアロン実行ファイルを生成します。

すべてのバイナリは以下の要件を満たします：
- **静的リンク**: mingw DLLに依存しない
- **スタンドアロン**: 単一の実行ファイルで動作
- **音声出力**: すぐにスピーカーから音を鳴らせる

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
│   ├── rust/                      # Rust実装
│   ├── go/                        # Go実装
│   ├── python/                    # Python実装
│   └── typescript_node/           # TypeScript/Node.js実装
├── scripts/                       # ビルドスクリプト
│   ├── build_rust.sh
│   ├── build_go.sh
│   ├── build_python.sh
│   ├── build_typescript.sh
│   └── build_all.sh
├── binaries/                      # ビルド済みバイナリ（GitHub Actions）
│   ├── rust/
│   ├── go/
│   ├── python/
│   └── typescript/
└── .github/workflows/
    └── daily-build.yml           # 毎日のビルドワークフロー
```

## 使用ライブラリ

### YM2151エミュレータライブラリ

1. **Nuked-OPM** (推奨)
   - リポジトリ: https://github.com/nukeykt/Nuked-OPM
   - サイクル精度の高いC実装
   - すべての言語から利用可能

2. **libymfm** (代替案)
   - リポジトリ: https://github.com/aaronsgiles/ymfm
   - モダンなC++実装

### 音声出力ライブラリ

- **Rust**: cpal (WASAPI対応)
- **Go**: oto (Ebitengine)
- **Python**: sounddevice (PortAudio)
- **TypeScript/Node.js**: speaker

詳細は [docs/libraries.md](docs/libraries.md) を参照。

## ビルド方法

### WSL2でのビルド

各言語のビルドスクリプトを実行：

```bash
# すべてビルド
./scripts/build_all.sh

# 個別にビルド
./scripts/build_rust.sh
./scripts/build_go.sh
./scripts/build_python.sh      # Windows環境が必要
./scripts/build_typescript.sh  # Windows環境が必要
```

### 前提条件

#### WSL2 (Ubuntu)

```bash
# 共通
sudo apt-get update
sudo apt-get install -y mingw-w64

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add x86_64-pc-windows-gnu

# Go
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

#### Windows (Python/TypeScript)

```powershell
# Python
python -m pip install pyinstaller

# Node.js
npm install -g pkg
```

## GitHub Actions

毎日午前0時（UTC）に自動的にすべてのバイナリをビルドし、`binaries/` ディレクトリにコミットします。

ワークフローの詳細は [docs/github_actions_plan.md](docs/github_actions_plan.md) を参照。

### 手動実行

GitHub Actionsページから「Daily Windows Binary Build」ワークフローを手動で実行できます。

## 実装計画

各言語の詳細な実装計画は以下のドキュメントを参照：

- [Rust実装計画](docs/implementation_plan_rust.md)
- [Go実装計画](docs/implementation_plan_go.md)
- [Python実装計画](docs/implementation_plan_python.md)
- [TypeScript/Node.js実装計画](docs/implementation_plan_typescript.md)
- [GitHub Actions実装計画](docs/github_actions_plan.md)

## バイナリの使用方法

```bash
# 例: Rustバイナリの実行
./binaries/rust/ym2151-emu.exe --sample-rate 44100 --duration 5

# ヘルプの表示
./binaries/rust/ym2151-emu.exe --help
```

## 開発ステータス

- [x] リポジトリ初期設定
- [x] YM2151ライブラリリストの作成
- [x] 各言語の実装計画書作成
- [x] GitHub Actions実装計画書作成
- [x] ビルドスクリプトの作成
- [x] GitHub Actionsワークフローの作成
- [ ] Rust実装
- [ ] Go実装
- [ ] Python実装
- [ ] TypeScript/Node.js実装

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