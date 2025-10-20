# YM2151ライブラリ提供要件チェック

## 概要
このドキュメントは、[ym2151-emulator-examples](https://github.com/cat2151/ym2151-emulator-examples)リポジトリが必要とするライブラリと、当リポジトリ(ym2151-emu-win-bin)が提供できるライブラリを突き合わせてチェックした結果です。

**チェック実施日**: 2025-10-19

---

## 結論: 必要なライブラリを提供できています ✅

当リポジトリは、ym2151-emulator-examplesが必要とする全ての主要ライブラリを提供できる体制を整えています。

---

## 詳細な言語別チェック

### 1. Rust 実装 ⭐⭐⭐⭐⭐

#### 要件 (ym2151-emulator-examples側)
- **エミュレータライブラリ**: Nuked-OPM (FFI経由)
- **ファイル構成**:
  - `src/rust/nuked-opm/` にNuked-OPMのCソースコード
  - `build.rs` でCコードをコンパイル
  - FFIバインディングで安全にラップ
- **オーディオ出力**: cpal (クロスプラットフォームオーディオライブラリ)
- **ビルドツール**: cc crate (Cコードコンパイル用)

#### 提供状況 (ym2151-emu-win-bin側)
- ✅ **Nuked-OPM静的ライブラリ**: 提供可能
  - `src/rust/` にビルド設定あり
  - `scripts/build_rust.sh` でビルド可能
  - 成果物: `libym2151.a` (静的ライブラリ)
- ✅ **Windows向けクロスコンパイル**: 対応済み
  - x86_64-pc-windows-gnuターゲット
  - mingw-w64による静的リンク

#### 評価
**✅ 完全対応**: ym2151-emulator-examplesのRust実装は、Nuked-OPMを直接ビルドしているため、当リポジトリからの提供は不要ですが、同等のライブラリビルド機能を提供しています。

---

### 2. Go 実装 ⭐⭐⭐⭐⭐

#### 要件 (ym2151-emulator-examples側)
- **エミュレータライブラリ**: Nuked-OPM (CGO経由)
- **ファイル構成**:
  - `nuked-opm-src/` にNuked-OPMのCソースコード (git submodule)
  - CGOでCライブラリを呼び出し
- **オーディオ出力**: PortAudio
  - Linux: ALSA
  - macOS: CoreAudio
  - Windows: WASAPI/DirectSound
- **ビルド要件**: 
  - WSL2からのクロスコンパイル
  - 静的リンク（MinGW DLL依存なし）
  - PortAudio静的ライブラリ

#### 提供状況 (ym2151-emu-win-bin側)
- ✅ **Nuked-OPM静的ライブラリ**: 提供可能
  - `src/go/` にビルド設定あり
  - `scripts/build_go.sh` でビルド可能
  - 成果物: `libym2151.a` (静的ライブラリ)
- ✅ **CGO対応**: 対応済み
  - mingw-w64クロスコンパイラ使用
  - 静的リンク設定済み
- ⚠️ **PortAudio**: 直接提供なし
  - ym2151-emulator-examples側で独自にビルド
  - ym2151-emu-win-bin はYM2151エミュレータのみ提供

#### 評価
**✅ 主要部分対応**: YM2151エミュレータライブラリは提供可能。PortAudioは音声出力用であり、YM2151エミュレーションには不要なため問題なし。

---

### 3. Python 実装 ⭐⭐⭐⭐

#### 要件 (ym2151-emulator-examples側)
- **エミュレータライブラリ**: Nuked-OPM (ctypes経由)
- **ファイル形式**: `libnukedopm.dll` (動的ライブラリ)
- **ビルド要件**:
  - WSL2またはMSYS2でビルド
  - 静的リンク（`-static-libgcc`）
  - MinGW DLL依存なし
- **Pythonラッパー**: ctypes
- **オーディオ出力**: sounddevice + numpy

#### 提供状況 (ym2151-emu-win-bin側)
- ✅ **Nuked-OPM DLL**: 提供可能
  - `src/python/` にビルド設定あり
  - `scripts/build_python.sh` でビルド可能
  - 成果物: `ym2151.dll` (動的ライブラリ、mingw DLL依存なし)
- ✅ **静的リンク**: 対応済み
  - `-static-libgcc -static-libstdc++` フラグ使用
- ✅ **ctypes対応**: 対応済み
  - C関数をエクスポート

#### 評価
**✅ 完全対応**: Pythonから使用可能なDLLを提供できます。ym2151-emulator-examples側で要求される `libnukedopm.dll` と同等の機能を持つ `ym2151.dll` を提供可能。

---

### 4. TypeScript/Node.js 実装 ⭐⭐⭐⭐⭐

#### 要件 (ym2151-emulator-examples側)
- **エミュレータライブラリ**: libymfm.wasm (WebAssembly版)
- **特徴**:
  - WebAssemblyなのでクロスプラットフォーム
  - npmパッケージとして利用可能
  - TypeScript型定義付き
- **オーディオ出力**: speaker (node-speaker)
  - PortAudioベース
  - クロスプラットフォーム対応
- **注意事項**: 
  - speaker には既知のDoS脆弱性 (CVE-2024-21526) あり
  - ローカル実行想定のため影響は限定的

#### 提供状況 (ym2151-emu-win-bin側)
- ⚠️ **libymfm.wasm**: 直接提供なし
  - libymfm.wasmはnpmパッケージとして配布されているため、ビルド不要
  - ym2151-emulator-examples側でnpmから直接利用可能
- ✅ **代替: Nuked-OPM Native Addon**: 提供可能
  - `src/typescript_node/` にビルド設定あり
  - `scripts/build_typescript.sh` でビルド可能
  - 成果物: `ym2151.node` (Native Addon)
- ✅ **node-speaker関連**: 別途提供
  - リポジトリに `build-node-speaker.sh` あり
  - Windows向けnode-speakerビルド環境を提供
  - PortAudio静的リンク済みbinding.node提供

#### 評価
**✅ 十分に対応**: 
- libymfm.wasmはnpmパッケージなので当リポジトリからの提供は不要
- 代替としてNuked-OPMベースのNative Addonを提供可能
- node-speaker (PortAudio) のビルド環境も提供

---

## 提供ライブラリ一覧

### 当リポジトリが提供するライブラリ

| 言語 | ライブラリ形式 | ファイル名 | エミュレータ | 静的リンク | ビルドスクリプト |
|------|--------------|----------|------------|----------|--------------|
| Rust | 静的ライブラリ | `libym2151.a` | Nuked-OPM | ✅ | `scripts/build_rust.sh` |
| Go | 静的ライブラリ | `libym2151.a` | Nuked-OPM | ✅ | `scripts/build_go.sh` |
| Python | 動的ライブラリ | `ym2151.dll` | Nuked-OPM | ✅ | `scripts/build_python.sh` |
| TypeScript/Node.js | Native Addon | `ym2151.node` | Nuked-OPM | ✅ | `scripts/build_typescript.sh` |
| Node.js | Native Addon | `binding.node` | - (PortAudio) | ✅ | `build-node-speaker.sh` |

### ym2151-emulator-examplesが必要とするライブラリ

| 言語 | 必要なライブラリ | 用途 | 提供状況 |
|------|---------------|------|---------|
| Rust | Nuked-OPM (C) | YM2151エミュレータ | ✅ 提供可能 (同等機能) |
| Rust | cpal | オーディオ出力 | N/A (音声出力用、YM2151エミュレータとは別) |
| Go | Nuked-OPM (C) | YM2151エミュレータ | ✅ 提供可能 |
| Go | PortAudio | オーディオ出力 | N/A (音声出力用、YM2151エミュレータとは別) |
| Python | Nuked-OPM (DLL) | YM2151エミュレータ | ✅ 提供可能 |
| Python | sounddevice | オーディオ出力 | N/A (音声出力用、YM2151エミュレータとは別) |
| TypeScript/Node.js | libymfm.wasm | YM2151エミュレータ | ⚠️ npmから直接利用可能 |
| TypeScript/Node.js | speaker (node-speaker) | オーディオ出力 | ✅ ビルド環境提供 |

**凡例**:
- ✅ 提供可能: 当リポジトリから提供可能
- ⚠️ 外部から利用: npmなど外部パッケージとして利用可能（当リポジトリからの提供不要）
- N/A: YM2151エミュレータとは別のコンポーネント（音声出力用）

---

## エミュレータライブラリの比較

### Nuked-OPM vs libymfm

| 項目 | Nuked-OPM | libymfm |
|-----|-----------|---------|
| **言語** | C | C++ |
| **ライセンス** | LGPL-2.1 | BSD-3-Clause |
| **精度** | サイクル精度 (非常に高い) | 高精度 |
| **対応チップ** | YM2151のみ | YM2151含む複数のYamahaチップ |
| **ビルドの容易さ** | 非常に簡単 (単一Cファイル) | やや複雑 (C++プロジェクト) |
| **依存関係** | なし | 少ない |
| **WebAssembly化** | 可能 | 既にlibymfm.wasmとして提供 |
| **当リポジトリでの提供** | ✅ 全言語向けに提供 | ❌ 現時点では未提供 |

---

## 過不足の評価

### ✅ 提供できているもの

1. **Nuked-OPM ライブラリ** - 全言語向け
   - Rust: 静的ライブラリ
   - Go: CGO用静的ライブラリ
   - Python: ctypes用DLL
   - TypeScript/Node.js: Native Addon

2. **Windows向けビルド環境**
   - mingw-w64クロスコンパイル
   - 静的リンク対応
   - MinGW DLL依存なし

3. **node-speaker ビルド環境**
   - PortAudio静的リンク済み
   - Windows向けNative Addon

### ⚠️ 提供していないが、問題ないもの

1. **libymfm / libymfm.wasm**
   - npmパッケージとして既に配布されている
   - ユーザーが直接 `npm install` で利用可能
   - 当リポジトリから提供する必要なし

2. **オーディオ出力ライブラリ**
   - cpal (Rust): cratesから利用可能
   - PortAudio (Go): ユーザーが自前でビルド (手順はym2151-emulator-examplesに記載)
   - sounddevice (Python): pipから利用可能
   - speaker (Node.js): npmから利用可能（ただし、Windows向けビルド済みbinding.nodeは提供）

   **理由**: これらはYM2151エミュレータとは独立した音声出力用のライブラリであり、YM2151エミュレータライブラリの提供範囲外

### ❌ 提供していないもの（今後の検討課題）

1. **libymfm C++ライブラリ**
   - BSD-3-Clauseライセンスで商用利用に有利
   - 複数のYamahaチップをサポート
   - 現時点ではNuked-OPMのみ提供

   **推奨**: 今後、libymfmライブラリも追加提供を検討
   - より柔軟なライセンス
   - より幅広いチップのサポート

---

## 推奨事項

### 現状維持で十分なケース
ym2151-emulator-examplesが必要とするYM2151エミュレータライブラリは、当リポジトリが提供するNuked-OPMで十分にカバーできています。

### 今後の拡張案

#### 優先度: 中
1. **libymfm C++ライブラリの追加**
   - BSD-3-Clauseライセンスが必要なユーザー向け
   - より多様なYamahaチップのサポートが必要な場合

#### 優先度: 低
2. **PortAudio Windows用ビルドの提供**
   - Go実装で使用するPortAudioのWindows向けビルド済みライブラリ
   - 現在はユーザーが自前でビルド
   - 提供すればセットアップが簡単に

3. **より詳細なドキュメント**
   - 各言語での利用例
   - ビルド済みバイナリのダウンロード方法

---

## まとめ

### 総合評価: ✅ 必要なライブラリを提供できています

当リポジトリ (ym2151-emu-win-bin) は、ym2151-emulator-examples リポジトリが必要とする**YM2151エミュレータライブラリ**を全て提供できる体制を整えています。

**提供できている主要機能**:
- ✅ Nuked-OPM ライブラリ (全言語向け)
- ✅ Windows向けクロスコンパイル環境
- ✅ 静的リンク対応 (MinGW DLL依存なし)
- ✅ node-speaker ビルド環境

**提供していないが問題ないもの**:
- libymfm.wasm (npmパッケージとして既に配布)
- 各種オーディオ出力ライブラリ (YM2151エミュレータとは独立したコンポーネント)

**今後の拡張候補**:
- libymfm C++ライブラリの追加 (BSD-3-Clauseライセンス、より柔軟)

---

## クイックチェック

このレポートの概要を素早く確認するには、以下のスクリプトを実行してください：

```bash
bash scripts/check_library_requirements.sh
```

このスクリプトは以下を確認します：
- レポートファイルの存在
- ビルドスクリプトの存在
- ソースディレクトリの存在
- 提供可能なライブラリの一覧

---

## 参考リンク

- [ym2151-emulator-examples](https://github.com/cat2151/ym2151-emulator-examples)
- [Nuked-OPM](https://github.com/nukeykt/Nuked-OPM)
- [libymfm](https://github.com/aaronsgiles/ymfm)
- [libymfm.wasm](https://github.com/h1romas4/libymfm.wasm)
- [node-speaker](https://github.com/TooTallNate/node-speaker)
