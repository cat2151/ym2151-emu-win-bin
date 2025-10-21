# ym2151-emu-win-bin

Windows用のnode-speakerライブラリビルド環境

[日本語ドキュメント](QUICKSTART.ja.md) | [アーキテクチャ解説（日本語）](ARCHITECTURE.ja.md) | [ライブラリ要件チェック](docs/LIBRARY_REQUIREMENT_CHECK.md) | [Library Requirements Check (EN)](docs/LIBRARY_REQUIREMENT_CHECK.en.md)

## 概要

このリポジトリは、Windows環境でnode-speakerライブラリをネイティブビルドするためのスクリプトとGitHub Actions ワークフローを提供します。

用途:
- Windows + Node.js + PortAudio + node-speaker + YM2151 emu

## 特徴

- MSYS2 mingw64環境でのネイティブビルド
- mingwランタイムの静的リンク（static linking）
- PortAudioの静的リンク
- GitHub Actions による自動ビルド

## ビルド方法

### GitHub Actions でのビルド（推奨）

1. このリポジトリをフォーク、またはクローン
2. GitHub Actions の "Build node-speaker with Static Linking" ワークフローを実行
3. ビルドされたアーティファクトをダウンロード

### ローカルでのビルド（Windows + MSYS2）

#### 前提条件

1. MSYS2 をインストール: https://www.msys2.org/
2. MSYS2 MINGW64 シェルを起動

#### ビルド手順

```bash
# リポジトリをクローン
git clone https://github.com/cat2151/ym2151-emu-win-bin.git
cd ym2151-emu-win-bin

# ビルドスクリプトを実行
./build-node-speaker.sh
```

ビルドされたライブラリは `output/` ディレクトリに出力されます。

## 出力ファイル

- `output/binding.node` - ネイティブアドオン（PortAudio静的リンク済み）
- `output/package.json` - node-speaker のパッケージ情報
- `output/lib/` - node-speaker の JavaScript ライブラリ

## 使用方法

ビルドされた `binding.node` を既存の node-speaker パッケージに配置して使用します:

```bash
# Node.js プロジェクトに node-speaker をインストール
npm install speaker

# ビルドされた binding.node を配置
cp output/binding.node node_modules/speaker/build/Release/
```

## トラブルシューティング

### ビルドが失敗する場合

1. MSYS2 のパッケージを更新:
   ```bash
   pacman -Syu
   ```

2. 必要なパッケージがインストールされているか確認:
   ```bash
   pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-portaudio mingw-w64-x86_64-pkg-config
   ```

3. Node.js のバージョンを確認（Node.js 18 推奨）

### 実行時エラー

静的リンクされているため、追加のDLLは不要です。エラーが発生する場合:
- Node.js のバージョンがビルド時と一致しているか確認
- binding.node ファイルが正しく配置されているか確認

## ライセンス

MIT License

## 関連リンク

- [node-speaker](https://github.com/TooTallNate/node-speaker)
- [PortAudio](http://www.portaudio.com/)
- [MSYS2](https://www.msys2.org/)
Windows向け公式Nuked-OPMライブラリバイナリのビルドリポジトリ

## 概要

このリポジトリは、**公式Nuked-OPM** (https://github.com/nukeykt/Nuked-OPM) YM2151エミュレータを、複数のプログラミング言語（Rust、Go、Python、TypeScript/Node.js）から利用可能な形式でビルドし、Windows向けのライブラリバイナリを生成します。

### 重要: ラッパーではなく公式APIを提供

このリポジトリは**カスタムラッパーを提供しません**。すべてのライブラリは公式Nuked-OPMのAPIをそのまま提供します：
- 関数名: `OPM_Reset()`, `OPM_Write()`, `OPM_Clock()`, `OPM_Read()` など
- 構造体: `opm_t`
- シグネチャ: 公式opm.hと完全に一致

すべてのライブラリバイナリは以下の要件を満たします：
- **公式API**: Nuked-OPMの公式APIをそのまま提供（ラッパーなし）
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

1. **Nuked-OPM** (公式)
   - リポジトリ: https://github.com/nukeykt/Nuked-OPM
   - サイクル精度の高いC実装
   - 公式APIをそのまま提供（カスタムラッパーなし）
   - 各言語から利用可能な形式でビルド

### ビルド成果物と公式API

各言語向けに以下の形式のライブラリバイナリを生成：

- **Rust**: `libnukedopm.a` (静的ライブラリ) / `nukedopm.dll` (動的ライブラリ)
  - 公式OPM_*関数をエクスポート
- **Go**: `libnukedopm.a` (静的ライブラリ) - CGO経由で利用
  - 公式OPM_*関数をエクスポート
- **Python**: `nukedopm.dll` (動的ライブラリ) - ctypes経由で利用
  - 公式OPM_*関数をエクスポート
  - 後方互換性のため `ym2151.dll` も提供
- **TypeScript/Node.js**: `.dll` または `.node` (Native Addon)

**すべてのライブラリが提供する関数（公式Nuked-OPM API）**:
- `void OPM_Reset(opm_t *chip)`
- `void OPM_Write(opm_t *chip, uint32_t port, uint8_t data)`
- `void OPM_Clock(opm_t *chip, int32_t *output, uint8_t *sh1, uint8_t *sh2, uint8_t *so)`
- `uint8_t OPM_Read(opm_t *chip, uint32_t port)`
- その他の公式API関数

詳細は [docs/libraries.md](docs/libraries.md) および [docs/OFFICIAL_API_ANALYSIS.md](docs/OFFICIAL_API_ANALYSIS.md) を参照。

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

各ライブラリは独立したワークフローでビルドされ、毎日午前0時（UTC）に自動実行されます。
成功したビルドは自動的に `binaries/` ディレクトリにコミットされます。

**すべてのライブラリは公式Nuked-OPM APIを提供します**（カスタムラッパーなし）

### ワークフロー一覧

- **Build Rust Library** (`.github/workflows/build-rust.yml`)
  - 実行環境: ubuntu-latest
  - 出力: `binaries/rust/libnukedopm.a`, `binaries/rust/nukedopm.dll`
  - API: 公式OPM_*関数

- **Build Go Library** (`.github/workflows/build-go.yml`)
  - 実行環境: ubuntu-latest
  - 出力: `binaries/go/libnukedopm.a`
  - API: 公式OPM_*関数

- **Build Python Library** (`.github/workflows/build-python.yml`)
  - 実行環境: ubuntu-latest
  - 出力: `binaries/python/nukedopm.dll`, `binaries/python/ym2151.dll` (legacy)
  - API: 公式OPM_*関数

- **Build TypeScript/Node.js Library** (`.github/workflows/build-typescript.yml`)
  - 実行環境: windows-latest
  - 出力: `binaries/typescript/ym2151.node`
  - API: 公式OPM_*関数（またはNative Addon wrapper）

### ワークフロー分割のメリット

1. **障害の局所化**: 1つのライブラリが失敗しても、他のライブラリのビルドは継続されます
2. **部分的な成功**: 成功したライブラリは自動的にコミットされます
3. **デバッグの容易さ**: 問題のあるライブラリに集中できます
4. **並列実行**: 各ライブラリが独立して並列ビルド可能です
5. **リソース効率**: 失敗したワークフローのみ再実行できます

詳細は [docs/automation_plan.md](docs/automation_plan.md) および [docs/workflow_failure_analysis.md](docs/workflow_failure_analysis.md) を参照。

### 手動実行

GitHub Actionsページから各ワークフローを個別に手動実行できます：
- "Build Rust Library"
- "Build Go Library"
- "Build Python Library"
- "Build TypeScript/Node.js Library"

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

## ライブラリ提供要件チェック

[ym2151-emulator-examples](https://github.com/cat2151/ym2151-emulator-examples)リポジトリが必要とするライブラリと、当リポジトリが提供できるライブラリの突き合わせチェックを実施しました。

**結論**: ✅ **必要なライブラリを提供できています**

詳細な比較結果とライブラリ一覧は以下のドキュメントを参照してください：
- [日本語版レポート](docs/LIBRARY_REQUIREMENT_CHECK.md)
- [English Report](docs/LIBRARY_REQUIREMENT_CHECK.en.md)

### 提供可能なライブラリ

| 言語 | ライブラリ形式 | エミュレータ | 静的リンク |
|------|--------------|------------|----------|
| Rust | 静的ライブラリ (`.a`) | Nuked-OPM | ✅ |
| Go | 静的ライブラリ (`.a`) | Nuked-OPM | ✅ |
| Python | 動的ライブラリ (`.dll`) | Nuked-OPM | ✅ |
| TypeScript/Node.js | Native Addon (`.node`) | Nuked-OPM | ✅ |
| Node.js | Native Addon (`.node`) | PortAudio | ✅ |

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
