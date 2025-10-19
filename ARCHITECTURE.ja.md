# ビルドシステムのアーキテクチャ

このドキュメントでは、node-speakerのビルドシステムのアーキテクチャと設計判断について説明します。

## システム概要

```
GitHub Actions (Windows Runner)
    ↓
MSYS2 MINGW64 環境
    ↓
Build Script (build-node-speaker.sh)
    ↓
node-speaker + PortAudio (静的リンク)
    ↓
output/binding.node (ネイティブアドオン)
```

## 技術スタック

### MSYS2 MINGW64

- **選択理由**: Windows上でPOSIX環境とネイティブWindowsバイナリを両立
- **mingw64**: ネイティブWindowsアプリケーション向けのGCCツールチェーン
- **利点**:
  - Linuxライクなビルド環境
  - Windows APIを直接使用
  - 最新のGCCバージョン

### 静的リンクの仕組み

#### mingwランタイムの静的リンク

```bash
export LDFLAGS="-static-libgcc -static-libstdc++"
```

これにより以下のライブラリが静的リンクされます:
- `libgcc_s_seh-1.dll` → 静的リンク
- `libstdc++-6.dll` → 静的リンク

**結果**: C/C++ランタイムのDLL不要

#### PortAudioの静的リンク

MSYS2のPortAudioパッケージは静的ライブラリを含んでいます:
- `/mingw64/lib/libportaudio.a` (静的ライブラリ)
- `/mingw64/lib/libportaudio.dll.a` (動的リンク用)

node-gypが`pkg-config`を使用してPortAudioをリンクする際、
適切なフラグを設定することで静的ライブラリを選択します。

## ビルドプロセスの詳細

### 1. 環境セットアップ

```yaml
- name: Setup MSYS2
  uses: msys2/setup-msys2@v2
  with:
    msystem: MINGW64
```

MSYS2環境を初期化し、MINGW64サブシステムを選択します。

### 2. 依存関係のインストール

```bash
pacman -S --noconfirm \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-portaudio \
    mingw-w64-x86_64-pkg-config \
    mingw-w64-x86_64-nodejs
```

### 3. node-speakerのクローンとビルド

```bash
git clone https://github.com/TooTallNate/node-speaker.git
cd node-speaker
npm install --ignore-scripts
node-gyp configure build --release
```

### 4. 成果物の収集

ビルドされた`binding.node`と必要なファイルを`output/`にコピー。

## node-gypの動作

### binding.gypの解析

node-speakerの`binding.gyp`は以下のような構造:

```python
{
  'targets': [{
    'target_name': 'binding',
    'sources': ['src/binding.cc'],
    'libraries': ['<!@(pkg-config --libs portaudio-2.0)'],
    'include_dirs': ['<!@(pkg-config --cflags-only-I portaudio-2.0 | sed s/-I//g)']
  }]
}
```

`pkg-config`を使用してPortAudioのビルド設定を取得します。

### 静的リンクの実現

`LDFLAGS`環境変数により、リンカーに静的リンクのオプションが渡されます:

```bash
gcc ... -static-libgcc -static-libstdc++ -lportaudio ...
```

リンカーは以下の順序でライブラリを検索:
1. `-l`オプションで指定されたライブラリ
2. 静的ライブラリ（`.a`）が優先される（`-static`フラグの効果）
3. `/mingw64/lib/libportaudio.a`を使用

## 依存関係の分析

### binding.nodeの依存関係

ビルドされた`binding.node`の依存関係は最小限です:

```
binding.node
├── kernel32.dll (Windows システムDLL)
├── msvcrt.dll (Windows システムDLL)
├── winmm.dll (Windows マルチメディアAPI)
└── (その他のシステムDLL)
```

**重要**: mingwランタイムやPortAudioのDLLは不要！

## トラブルシューティングガイド

### ビルドが失敗する場合

#### 問題: pkg-configがPortAudioを見つけられない

**原因**: PKG_CONFIG_PATHが正しく設定されていない

**解決策**:
```bash
export PKG_CONFIG_PATH="/mingw64/lib/pkgconfig:$PKG_CONFIG_PATH"
pkg-config --list-all | grep portaudio
```

#### 問題: node-gypが失敗する

**原因**: Python のバージョン不一致

**解決策**:
```bash
pacman -S mingw-w64-x86_64-python
npm config set python /mingw64/bin/python
```

#### 問題: リンクエラー

**原因**: 静的リンクフラグが正しく渡されていない

**解決策**: 環境変数を確認:
```bash
echo $LDFLAGS
echo $CFLAGS
echo $CXXFLAGS
```

### 実行時エラー

#### 問題: "指定されたモジュールが見つかりません"

**原因**:
1. Node.jsのバージョン不一致
2. アーキテクチャの不一致（x86 vs x64）

**解決策**:
```bash
node --version  # ビルド時と同じバージョンを使用
file binding.node  # PE32+（64-bit）であることを確認
```

#### 問題: "プロシージャ エントリ ポイントが見つかりません"

**原因**: DLLのバージョン不一致（通常、静的リンクではこの問題は発生しません）

**解決策**: 
- binding.nodeを再ビルド
- システムのDLLパスを確認

## パフォーマンス最適化

### ビルド最適化

コンパイラ最適化フラグを追加:

```bash
export CFLAGS="-O3 -march=native"
export CXXFLAGS="-O3 -march=native"
```

**注意**: `-march=native`は、ビルド環境のCPUに最適化されますが、
他のCPUでは動作しない可能性があります。

### 実行時最適化

- **バッファサイズの調整**: レイテンシとCPU使用率のバランス
- **サンプルレートの選択**: 44100Hz vs 48000Hz
- **ビット深度**: 16-bit vs 24-bit

## セキュリティ考慮事項

### 静的リンクのセキュリティメリット

1. **依存関係の明確化**: すべての依存関係がバイナリに含まれる
2. **バージョン固定**: 外部DLLのバージョン変更による影響なし
3. **監査の容易さ**: 単一のバイナリファイルのみ

### セキュリティアップデート

静的リンクの欠点:
- セキュリティパッチが自動的に適用されない
- 再ビルドが必要

**推奨**: 定期的な再ビルドとテスト

## 将来の拡張

### 追加の静的リンクライブラリ

他のオーディオライブラリも同様に静的リンク可能:
- libsndfile (WAV/FLAC/Oggファイルのサポート)
- libopus (Opusコーデック)
- libvorbis (Vorbisコーデック)

### クロスコンパイル

MSYS2はクロスコンパイルにも対応:
```bash
# 32-bit版のビルド
export MSYSTEM=MINGW32
pacman -S mingw-w64-i686-gcc mingw-w64-i686-portaudio
```

### CI/CDパイプラインの拡張

- 複数のNode.jsバージョンでのビルド
- 自動テストの実行
- パフォーマンスベンチマーク

## 参考資料

- [MSYS2公式ドキュメント](https://www.msys2.org/)
- [node-gyp公式ドキュメント](https://github.com/nodejs/node-gyp)
- [PortAudio公式サイト](http://www.portaudio.com/)
- [MinGW-w64プロジェクト](https://www.mingw-w64.org/)

## まとめ

このビルドシステムは以下を実現します:

✅ Windows環境でのネイティブビルド
✅ mingwランタイムの静的リンク
✅ PortAudioの静的リンク
✅ 自動化されたCI/CDパイプライン
✅ 再現可能なビルド環境
✅ 最小限の外部依存関係

これにより、YM2151エミュレータとの統合が容易になり、
配布も簡単になります。
