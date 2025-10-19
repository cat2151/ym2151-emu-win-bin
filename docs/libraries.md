# YM2151 Emulator Libraries for Windows

このドキュメントでは、Windowsで使用可能なYM2151エミュレータライブラリをリストアップします。

## 選定基準

1. **静的リンク対応**: mingw DLLに依存しないようにstatic linkingが可能であること
2. **Windows互換性**: WSL2からWindows向けにクロスコンパイル可能であること
3. **音声出力対応**: スピーカーから直接音を出力できること
4. **精度**: YM2151チップの正確なエミュレーションができること

## 推奨ライブラリ

### 1. Nuked-OPM

- **リポジトリ**: https://github.com/nukeykt/Nuked-OPM
- **言語**: C
- **ライセンス**: LGPL v2.1+
- **特徴**:
  - サイクル精度の高いYM2151エミュレータ
  - シンプルなC実装で、Rust/Go/Python/TypeScriptから利用可能
  - 静的リンクに対応
  - クロスコンパイルが容易

**対応言語別の利用方法**:
- **Rust**: FFI経由またはバインディング作成
- **Go**: CGO経由で利用
- **Python**: ctypesまたはCFFI経由で利用
- **TypeScript/Node.js**: Node.js N-API経由で利用

### 2. libymfm (ymfm)

- **リポジトリ**: https://github.com/aaronsgiles/ymfm
- **言語**: C++
- **ライセンス**: BSD-3-Clause
- **特徴**:
  - モダンなC++実装
  - 複数のYamahaチップをサポート（YM2151含む）
  - WebAssemblyへのコンパイルも可能
  - 高精度なエミュレーション

**対応言語別の利用方法**:
- **Rust**: cc crateまたはcxx crateで統合
- **Go**: CGO経由でC++ラッパー経由で利用
- **Python**: pybind11またはctypesでラッパー経由で利用
- **TypeScript/Node.js**: Node.js N-APIまたはWebAssembly経由で利用

## 音声出力ライブラリ

各言語でスピーカーから音を出力するために、以下のライブラリを使用します：

### Rust
- **cpal** (Cross-Platform Audio Library): https://github.com/RustAudio/cpal
  - クロスプラットフォーム対応
  - 低レイテンシ
  - Windows WASAPIサポート

### Go
- **oto** (Ebitengine): https://github.com/ebitengine/oto
  - シンプルなAPI
  - クロスプラットフォーム対応
  - 静的リンク対応

### Python
- **sounddevice**: https://github.com/spatialaudio/python-sounddevice
  - NumPy配列に対応
  - 低レイテンシ
  - PortAudio経由でWindows対応

### TypeScript/Node.js
- **speaker**: https://github.com/TooTallNate/node-speaker
  - PCMストリーム再生
  - クロスプラットフォーム対応
  - Windows対応

## 実装の優先順位

1. **第1優先**: Nuked-OPM + 各言語の音声出力ライブラリ
   - 理由: シンプルで静的リンクが容易、すべての言語から利用可能

2. **第2優先**: libymfm + 各言語の音声出力ライブラリ
   - 理由: より高度な機能が必要な場合の代替案

## クロスコンパイル環境

WSL2 (Ubuntu) から Windows向けバイナリをビルドするために、以下のツールを使用：

- **mingw-w64**: Windows向けクロスコンパイラ
  - `x86_64-w64-mingw32-gcc`: C/C++コンパイラ
  - `x86_64-w64-mingw32-ar`: アーカイバ

- **Rust**: `x86_64-pc-windows-gnu` ターゲット
- **Go**: `GOOS=windows GOARCH=amd64` でクロスコンパイル
- **Python**: PyInstallerまたはNuitkaでスタンドアロン実行ファイル作成
- **TypeScript/Node.js**: pkg または nexe でスタンドアロン実行ファイル作成

## 注意事項

- **mingw DLL依存を避ける**: すべてのバイナリは静的リンクで作成
  - Rustの場合: `-C target-feature=+crt-static` フラグを使用
  - Goの場合: `-ldflags "-linkmode external -extldflags '-static'"` を使用
  - Pythonの場合: PyInstallerの `--onefile` オプションを使用
  - Node.jsの場合: pkg で単一実行ファイルにバンドル

- **ライブラリの静的ビルド**: Nuked-OPMやlibymfmを静的ライブラリ(.a)としてビルド
