# クイックスタートガイド

node-speakerのWindows向け静的リンクビルドのクイックスタートガイドです。

## 目次

1. [GitHub Actionsでビルド（推奨）](#github-actionsでビルド推奨)
2. [ローカルでビルド](#ローカルでビルド)
3. [使用方法](#使用方法)
4. [よくある質問](#よくある質問)

## GitHub Actionsでビルド（推奨）

### 手順

1. **リポジトリをフォーク**
   - GitHubでこのリポジトリをフォーク

2. **ワークフローを実行**
   - Actionsタブを開く
   - "Build node-speaker with Static Linking"を選択
   - "Run workflow"をクリック

3. **アーティファクトをダウンロード**
   - ワークフロー実行が完了したら"Artifacts"からダウンロード
   - `node-speaker-static-mingw64.zip`を展開

### 自動ビルドの設定

以下のブランチにpushすると自動的にビルドされます:
- `main`
- `master`
- `develop`

タグをpushするとGitHub Releasesにも自動アップロードされます:
```bash
git tag v1.0.0
git push origin v1.0.0
```

## ローカルでビルド

### 必要なもの

- Windows 10/11
- MSYS2 (https://www.msys2.org/)

### インストール手順

#### 1. MSYS2のインストール

1. https://www.msys2.org/ からインストーラーをダウンロード
2. インストーラーを実行（デフォルト設定でOK）
3. インストール後、MSYS2を更新:
   ```bash
   pacman -Syu
   ```
4. ターミナルを再起動後、もう一度更新:
   ```bash
   pacman -Su
   ```

#### 2. ビルドの実行

1. **MSYS2 MINGW64シェルを起動**（重要: MINGW64を使用）

2. **リポジトリをクローン**
   ```bash
   cd ~
   git clone https://github.com/<your-username>/ym2151-emu-win-bin.git
   cd ym2151-emu-win-bin
   ```
   ※ `<your-username>`を実際のGitHubユーザー名に置き換えてください

3. **ビルドスクリプトを実行**
   ```bash
   ./build-node-speaker.sh
   ```

4. **ビルド完了を確認**
   ```bash
   ls -lh output/
   # binding.node が存在すればOK
   ```

### ビルド時間

初回ビルド: 約10-15分（パッケージのダウンロードを含む）
2回目以降: 約3-5分

## 使用方法

### 基本的な使い方

#### 1. Node.jsプロジェクトにインストール

```bash
# 通常のspeakerパッケージをインストール
npm install speaker
```

#### 2. ビルドしたbinding.nodeを配置

```bash
# ビルドしたbinding.nodeをコピー
cp output/binding.node node_modules/speaker/build/Release/
```

#### 3. コードで使用

```javascript
const Speaker = require('speaker');

const speaker = new Speaker({
  channels: 2,
  bitDepth: 16,
  sampleRate: 44100
});

// 音声データを書き込む
speaker.write(audioBuffer);
speaker.end();
```

### テストの実行

付属のテストスクリプトで動作確認:

```bash
node examples/test-speaker.js
```

正常に動作すれば、440Hzの音（ラの音）が2秒間再生されます。

## よくある質問

### Q1: ビルドが失敗します

**A**: 以下を確認してください:

1. **MSYS2 MINGW64シェルを使用していますか？**
   - MSYS2には複数のシェルがあります
   - 必ず"MINGW64"と表示されているシェルを使用

2. **MSYS2は最新ですか？**
   ```bash
   pacman -Syu
   ```

3. **エラーメッセージを確認**
   - パッケージが見つからない場合: `pacman -S [パッケージ名]`
   - pkg-configエラー: `export PKG_CONFIG_PATH="/mingw64/lib/pkgconfig"`

### Q2: binding.nodeが動作しません

**A**: 以下を確認:

1. **Node.jsのバージョンが一致していますか？**
   ```bash
   node --version
   # ビルド時と同じバージョンを使用
   ```

2. **64-bit版のNode.jsですか？**
   - 32-bit版のNode.jsでは動作しません

3. **ファイルパスは正しいですか？**
   ```bash
   # 正しい配置
   node_modules/speaker/build/Release/binding.node
   ```

### Q3: 他のPCで使えますか？

**A**: はい、使えます！

静的リンクされているため、以下の条件で動作します:
- Windows 10/11（64-bit）
- 同じバージョンのNode.js
- オーディオデバイスが利用可能

DLLのインストールは不要です。

### Q4: エラー「DLLが見つかりません」

**A**: 静的リンクされているので、このエラーは通常発生しません。

もし発生した場合:
1. binding.nodeを再ビルド
2. Windowsシステムの更新を確認
3. Visual C++ Redistributableがインストールされているか確認

### Q5: サンプルレートを変更したい

**A**: Speakerインスタンス作成時に指定:

```javascript
const speaker = new Speaker({
  channels: 2,
  bitDepth: 16,
  sampleRate: 48000  // 48kHzに変更
});
```

対応サンプルレート: 8000, 11025, 16000, 22050, 44100, 48000 Hz

### Q6: YM2151エミュレータとの統合方法は？

**A**: 以下のような流れになります:

```javascript
const Speaker = require('speaker');
const YM2151 = require('your-ym2151-module');

// Speakerの初期化
const speaker = new Speaker({
  channels: 2,
  bitDepth: 16,
  sampleRate: 44100
});

// YM2151エミュレータの初期化
const ym2151 = new YM2151(44100);

// オーディオループ
function generateAudio() {
  const bufferSize = 1024;
  const buffer = Buffer.alloc(bufferSize * 4);
  
  for (let i = 0; i < bufferSize; i++) {
    const [left, right] = ym2151.generateSample();
    buffer.writeInt16LE(left, i * 4);
    buffer.writeInt16LE(right, i * 4 + 2);
  }
  
  speaker.write(buffer);
}

// 定期的に音声を生成
setInterval(generateAudio, (1024 / 44100) * 1000);
```

## トラブルシューティング

### ログの確認

ビルドログを詳細表示:
```bash
./build-node-speaker.sh 2>&1 | tee build.log
```

### クリーンビルド

前回のビルドをクリーンアップしてから再ビルド:
```bash
rm -rf node-speaker output
./build-node-speaker.sh
```

### パッケージの再インストール

MSYS2パッケージに問題がある場合:
```bash
pacman -Rns mingw-w64-x86_64-portaudio
pacman -S mingw-w64-x86_64-portaudio
```

## 更なる情報

- 詳細な設定: [BUILD_CONFIGURATION.md](BUILD_CONFIGURATION.md)
- アーキテクチャ: [ARCHITECTURE.ja.md](ARCHITECTURE.ja.md)
- 英語版README: [README.md](README.md)

## サポート

問題が解決しない場合:
1. [GitHubのIssues](https://github.com/cat2151/ym2151-emu-win-bin/issues)で質問
2. ビルドログを添付
3. 使用環境（Windows, Node.js, MSYS2のバージョン）を記載

## ライセンス

MIT License - 自由に使用・改変・配布できます
