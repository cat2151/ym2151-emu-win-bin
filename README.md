# ym2151-emu-win-bin

Windows用のnode-speakerライブラリビルド環境

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