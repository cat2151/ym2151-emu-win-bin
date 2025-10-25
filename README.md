# ym2151-emu-win-bin

Windows向け公式Nuked-OPMライブラリバイナリのビルドリポジトリ

[ライブラリ要件チェック](docs/LIBRARY_REQUIREMENT_CHECK.md) | [Library Requirements Check (EN)](docs/LIBRARY_REQUIREMENT_CHECK.en.md)

## 概要

このリポジトリは、**公式Nuked-OPM** (https://github.com/nukeykt/Nuked-OPM) YM2151エミュレータを、複数のプログラミング言語（Rust、Go、Python）から利用可能な形式でビルドし、Windows向けのライブラリバイナリを生成します。

### 重要: ラッパーではなく公式APIを提供

このリポジトリは**カスタムラッパーを提供しません**。すべてのライブラリは公式Nuked-OPMのAPIをそのまま提供します：
- 関数名: `OPM_Reset()`, `OPM_Write()`, `OPM_Clock()`, `OPM_Read()` など
- 構造体: `opm_t`
- シグネチャ: 公式opm.hと完全に一致

すべてのライブラリバイナリは以下の要件を満たします：
- **公式API**: Nuked-OPMの公式APIをそのまま提供（ラッパーなし）
- **静的リンク対応**: mingw DLLに依存しない `.a` (static library) または `.dll` (dynamic library) を生成
- **言語バインディング対応**: Rust、Go、Pythonから利用可能
- **クロスプラットフォームビルド**: WSL2からWindows向けにビルド可能

## ディレクトリ構造

```
ym2151-emu-win-bin/
├── docs/                           # ドキュメント
│   ├── libraries.md               # 使用ライブラリのリスト
│   ├── implementation_plan_rust.md
│   ├── implementation_plan_go.md
│   └── implementation_plan_python.md
├── src/
│   ├── rust/                      # Rust用ライブラリビルド
│   ├── go/                        # Go用ライブラリビルド
│   └── python/                    # Python用ライブラリビルド
├── scripts/                       # ビルドスクリプト
│   ├── build_rust.sh
│   ├── build_go.sh
│   ├── build_python.sh
│   └── build_all.sh
├── binaries/                      # ビルド済みライブラリバイナリ（GitHub Actions）
│   ├── rust/
│   ├── go/
│   └── python/
└── .github/workflows/
    ├── build-rust.yml             # Rustライブラリビルド
    ├── build-go.yml               # Goライブラリビルド
    └── build-python.yml           # Pythonライブラリビルド
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
  - 出力: `binaries/python/nukedopm.dll`
  - API: 公式OPM_*関数

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

## ビルド済みバイナリの使用方法

ビルド済みのライブラリバイナリは `binaries/` ディレクトリに格納されており、以下の方法でアクセスできます：

### 直接ダウンロード

特定のバイナリをダウンロード：
```bash
# Python用DLL
curl -L -o nukedopm.dll https://github.com/cat2151/ym2151-emu-win-bin/raw/main/binaries/python/nukedopm.dll

# Rust用静的ライブラリ
curl -L -o libnukedopm.a https://github.com/cat2151/ym2151-emu-win-bin/raw/main/binaries/rust/libnukedopm.a

# Go用静的ライブラリ
curl -L -o libnukedopm.a https://github.com/cat2151/ym2151-emu-win-bin/raw/main/binaries/go/libnukedopm.a
```

### Git Submoduleとして使用

他のプロジェクトから参照する場合：
```bash
# サブモジュールとして追加
git submodule add https://github.com/cat2151/ym2151-emu-win-bin.git vendor/ym2151-binaries

# バイナリを参照
# Rust: vendor/ym2151-binaries/binaries/rust/libnukedopm.a
# Go:   vendor/ym2151-binaries/binaries/go/libnukedopm.a
# Python: vendor/ym2151-binaries/binaries/python/nukedopm.dll
```

### リポジトリをクローン

```bash
git clone https://github.com/cat2151/ym2151-emu-win-bin.git
# バイナリは binaries/ ディレクトリに配置されています
```

詳細は [binaries/README.md](binaries/README.md) を参照してください。

## 実装計画

各言語の詳細なビルド計画は以下のドキュメントを参照：

- [Rust用ライブラリビルド計画](docs/implementation_plan_rust.md)
- [Go用ライブラリビルド計画](docs/implementation_plan_go.md)
- [Python用ライブラリビルド計画](docs/implementation_plan_python.md)

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
lib = ctypes.CDLL('./binaries/python/nukedopm.dll')
```

## 開発ステータス

- [x] リポジトリ初期設定
- [x] YM2151ライブラリリストの作成
- [x] 各言語のビルド計画書作成
- [x] GitHub Actions実装計画書作成
- [x] ビルドスクリプトの作成
- [x] GitHub Actionsワークフローの作成
- [x] Rust用ライブラリビルド
- [x] Go用ライブラリビルド
- [x] Python用ライブラリビルド

## ライブラリ提供要件チェック

[ym2151-emulator-examples](https://github.com/cat2151/ym2151-emulator-examples)リポジトリが必要とするライブラリと、当リポジトリが提供できるライブラリの突き合わせチェックを実施しました。

**結論**: ✅ **必要なライブラリを提供できています**

詳細な比較結果とライブラリ一覧は以下のドキュメントを参照してください：
- [日本語版レポート](docs/LIBRARY_REQUIREMENT_CHECK.md)
- [English Report](docs/LIBRARY_REQUIREMENT_CHECK.en.md)

### 提供可能なライブラリ

| 言語 | ライブラリ形式 | エミュレータ | 静的リンク |
|------|--------------|------------|----------|
| Rust | 静的ライブラリ (`.a`) / 動的ライブラリ (`.dll`) | Nuked-OPM | ✅ |
| Go | 静的ライブラリ (`.a`) | Nuked-OPM | ✅ |
| Python | 動的ライブラリ (`.dll`) | Nuked-OPM | ✅ |

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
