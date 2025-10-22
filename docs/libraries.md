# YM2151 Emulator Libraries for Windows

このドキュメントでは、Windowsで使用可能なYM2151エミュレータライブラリと、そのビルド方法をリストアップします。

## 選定基準

1. **静的リンク対応**: mingw DLLに依存しないようにstatic linkingが可能であること
2. **Windows互換性**: WSL2からWindows向けにクロスコンパイル可能であること
3. **言語バインディング対応**: Rust、Go、Python、TypeScript/Node.jsから利用可能であること
4. **精度**: YM2151チップの正確なエミュレーションができること

## ビルド対象ライブラリ

### 1. Nuked-OPM（公式API）

- **リポジトリ**: https://github.com/nukeykt/Nuked-OPM
- **言語**: C
- **ライセンス**: LGPL v2.1+
- **特徴**:
  - サイクル精度の高いYM2151エミュレータ
  - シンプルなC実装で、Rust/Go/Python/TypeScriptから利用可能
  - 静的リンクに対応
  - クロスコンパイルが容易
  - **公式APIをそのまま提供**（カスタムラッパーなし）

**公式API（opm.hより）**:
```c
typedef struct { /* ... */ } opm_t;
void OPM_Reset(opm_t *chip);
void OPM_Write(opm_t *chip, uint32_t port, uint8_t data);
void OPM_Clock(opm_t *chip, int32_t *output, uint8_t *sh1, uint8_t *sh2, uint8_t *so);
uint8_t OPM_Read(opm_t *chip, uint32_t port);
// その他の関数...
```

**対応言語別のビルド方法**:
- **Rust**: cc crateでコンパイルして静的ライブラリ (`libnukedopm.a`) を生成
  - 公式OPM_*関数をそのままエクスポート
- **Go**: CGO経由で利用可能な静的ライブラリ (`libnukedopm.a`) を生成
  - 公式OPM_*関数をそのままエクスポート
- **Python**: 動的ライブラリ (`nukedopm.dll`) をビルドしてctypes経由で利用
  - 公式OPM_*関数をそのままエクスポート
- **TypeScript/Node.js**: Native Addon (`.node`) または動的ライブラリ (`.dll`) を生成
  - 公式OPM_*関数をそのままエクスポート

### 2. libymfm (ymfm)

- **リポジトリ**: https://github.com/aaronsgiles/ymfm
- **言語**: C++
- **ライセンス**: BSD-3-Clause
- **特徴**:
  - モダンなC++実装
  - 複数のYamahaチップをサポート（YM2151含む）
  - WebAssemblyへのコンパイルも可能
  - 高精度なエミュレーション

**対応言語別のビルド方法**:
- **Rust**: cc crateまたはcxx crateでコンパイルして静的ライブラリを生成
- **Go**: CGO経由でC++ラッパー経由で利用可能な形式でビルド
- **Python**: pybind11またはC++ラッパーで動的ライブラリ (.dll) を生成
- **TypeScript/Node.js**: Node.js N-APIでNative Addon (.node) を生成

## ビルド成果物（公式Nuked-OPM API）

各言語向けに以下の形式のライブラリファイルを生成：

### Rust
- **ファイル形式**: `libnukedopm.a` (静的ライブラリ), `nukedopm.dll` (動的ライブラリ)
- **用途**: Rustプロジェクトから直接リンク可能
- **API**: 公式Nuked-OPM API（OPM_Reset, OPM_Write, OPM_Clock等）

### Go
- **ファイル形式**: `libnukedopm.a` (静的ライブラリ)
- **用途**: CGOから利用可能
- **API**: 公式Nuked-OPM API（OPM_Reset, OPM_Write, OPM_Clock等）

### Python
- **ファイル形式**: `nukedopm.dll` (動的ライブラリ)
- **用途**: ctypesでロード可能
- **API**: 公式Nuked-OPM API（OPM_Reset, OPM_Write, OPM_Clock等）

### TypeScript/Node.js
- **ファイル形式**: `ym2151.node` (Native Addon) または `ym2151.dll`
- **用途**: require() でロード可能
- **API**: 公式Nuked-OPM API（OPM_Reset, OPM_Write, OPM_Clock等）

**重要**: すべてのライブラリは公式Nuked-OPM APIをそのまま提供します。カスタムラッパーは存在しません。

## 実装の優先順位

1. **第1優先**: Nuked-OPM静的ライブラリのビルド
   - 理由: シンプルで静的リンクが容易、すべての言語から利用可能

2. **第2優先**: libymfm静的ライブラリのビルド
   - 理由: より高度な機能が必要な場合の代替案

## クロスコンパイル環境

WSL2 (Ubuntu) から Windows向けライブラリをビルドするために、以下のツールを使用：

- **mingw-w64**: Windows向けクロスコンパイラ
  - `x86_64-w64-mingw32-gcc`: C/C++コンパイラ
  - `x86_64-w64-mingw32-ar`: アーカイバ (静的ライブラリ作成)
  - `x86_64-w64-mingw32-g++`: C++コンパイラ

## 各言語でのビルドターゲット

- **Rust**: ライブラリとしてビルドするための設定 (lib.rs)
- **Go**: CGO経由でリンク可能な静的ライブラリ
- **Python**: ctypesでロード可能なDLL
- **TypeScript/Node.js**: Native Addon形式でビルド

## 注意事項

- **mingw DLL依存を避ける**: すべてのライブラリは静的リンクで作成
  - 静的ライブラリ (.a) の場合: mingw-w64のstatic linkingを使用
  - 動的ライブラリ (.dll) の場合: `-static-libgcc -static-libstdc++` フラグを使用

- **ライブラリの静的ビルド**: Nuked-OPMを静的ライブラリ(.a)または独立したDLLとしてビルド

- **公式APIの提供**: すべてのライブラリは公式Nuked-OPM APIをそのまま提供
  - カスタムラッパーは存在しない
  - 関数名、シグネチャはopm.hと完全に一致
  - ユーザーは公式ドキュメントをそのまま参照可能
