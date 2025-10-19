# TypeScript/Node.js YM2151 Library

Nuked-OPMライブラリをWindows向けにビルドし、TypeScript/Node.jsからrequire()で利用可能なNative Addonを生成します。

## ビルド方法

```bash
# リポジトリのルートから実行
bash scripts/build_typescript.sh
```

このスクリプトは以下を実行します：
1. Nuked-OPMをvendor/nuked-opmにクローン（未取得の場合）
2. npm installで依存関係をインストール
3. node-gypでNative Addonをビルド

## 成果物

- `build/Release/ym2151.node` - Native Addon

## 前提条件

- Node.js (v16以上推奨)
- npm
- node-gyp
- Windows環境（またはGitHub Actions windows-latest）

## 利用方法

Node.jsから利用：

```javascript
const ym2151 = require('./build/Release/ym2151.node');

const chip = new ym2151.YM2151();
chip.reset();
chip.write(0x01, 0x02);
const samples = chip.clock(1024);
```

TypeScriptから利用：

```typescript
import { YM2151 } from './build/Release/ym2151.node';

const chip = new YM2151();
chip.reset();
const samples = chip.clock(1024);
```
