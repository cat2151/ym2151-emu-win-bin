# TypeScript/Node.js実装計画書

## 概要

TypeScript/Node.jsで、Nuked-OPMライブラリを使用したYM2151エミュレータCLIを作成します。
音声出力には`speaker`ライブラリを使用し、Windows向けに`pkg`でスタンドアロン実行ファイルを生成します。

## アーキテクチャ

```
src/typescript_node/
├── package.json        # プロジェクト設定
├── tsconfig.json       # TypeScript設定
├── binding.gyp         # Node.js Native Addonビルド設定
├── src/
│   ├── index.ts        # エントリポイント
│   ├── ym2151.ts       # YM2151エミュレータラッパー
│   └── audio.ts        # 音声出力ハンドラ
├── native/
│   ├── ym2151_addon.cc # Node.js Native Addon
│   └── nuked-opm/      # Nuked-OPMソースコード
│       ├── opm.h
│       └── opm.c
└── dist/               # ビルド出力
```

## 依存関係

### package.json

```json
{
  "name": "ym2151-emu",
  "version": "0.1.0",
  "description": "YM2151 Emulator CLI for Windows",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc && node-gyp rebuild",
    "start": "node dist/index.js",
    "package": "pkg dist/index.js --targets node18-win-x64 --output ym2151-emu.exe"
  },
  "dependencies": {
    "speaker": "^0.5.4",
    "commander": "^11.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "node-gyp": "^10.0.0",
    "pkg": "^5.8.1"
  },
  "bin": {
    "ym2151-emu": "./dist/index.js"
  }
}
```

## 実装ステップ

### 1. プロジェクト初期化

```bash
cd src/typescript_node
npm init -y
npm install speaker commander
npm install -D typescript @types/node node-gyp pkg
npx tsc --init
```

### 2. TypeScript設定

**tsconfig.json**:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### 3. Node.js Native Addonの実装

**binding.gyp**:
```json
{
  "targets": [
    {
      "target_name": "ym2151_addon",
      "sources": [
        "native/ym2151_addon.cc",
        "native/nuked-opm/opm.c"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")",
        "native/nuked-opm"
      ],
      "dependencies": [
        "<!(node -p \"require('node-addon-api').gyp\")"
      ],
      "cflags!": ["-fno-exceptions"],
      "cflags_cc!": ["-fno-exceptions"],
      "defines": ["NAPI_DISABLE_CPP_EXCEPTIONS"],
      "conditions": [
        [
          "OS=='win'",
          {
            "msvs_settings": {
              "VCCLCompilerTool": {
                "ExceptionHandling": 1,
                "RuntimeLibrary": 0
              }
            }
          }
        ]
      ]
    }
  ]
}
```

**native/ym2151_addon.cc**:
```cpp
#include <napi.h>
extern "C" {
    #include "nuked-opm/opm.h"
}

class YM2151Wrapper : public Napi::ObjectWrap<YM2151Wrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports) {
        Napi::Function func = DefineClass(env, "YM2151", {
            InstanceMethod("reset", &YM2151Wrapper::Reset),
            InstanceMethod("write", &YM2151Wrapper::Write),
            InstanceMethod("generateSamples", &YM2151Wrapper::GenerateSamples),
        });

        Napi::FunctionReference* constructor = new Napi::FunctionReference();
        *constructor = Napi::Persistent(func);
        env.SetInstanceData(constructor);

        exports.Set("YM2151", func);
        return exports;
    }

    YM2151Wrapper(const Napi::CallbackInfo& info) : Napi::ObjectWrap<YM2151Wrapper>(info) {
        // チップの初期化
        // 実際のNuked-OPMの初期化コードを追加
    }

private:
    opm_chip chip_;

    Napi::Value Reset(const Napi::CallbackInfo& info) {
        OPM_Reset(&chip_);
        return info.Env().Undefined();
    }

    Napi::Value Write(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();

        if (info.Length() < 2 || !info[0].IsNumber() || !info[1].IsNumber()) {
            Napi::TypeError::New(env, "Number expected").ThrowAsJavaScriptException();
            return env.Undefined();
        }

        uint32_t address = info[0].As<Napi::Number>().Uint32Value();
        uint32_t data = info[1].As<Napi::Number>().Uint32Value();

        OPM_Write(&chip_, address, data);
        return env.Undefined();
    }

    Napi::Value GenerateSamples(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();

        if (info.Length() < 1 || !info[0].IsNumber()) {
            Napi::TypeError::New(env, "Number expected").ThrowAsJavaScriptException();
            return env.Undefined();
        }

        uint32_t numFrames = info[0].As<Napi::Number>().Uint32Value();
        uint32_t bufferSize = numFrames * 2; // stereo

        Napi::Buffer<int16_t> buffer = Napi::Buffer<int16_t>::New(env, bufferSize);
        OPM_Clock(&chip_, buffer.Data(), numFrames);

        return buffer;
    }
};

Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
    return YM2151Wrapper::Init(env, exports);
}

NODE_API_MODULE(ym2151_addon, InitAll)
```

**注**: Node.js Native Addonのビルドには `node-addon-api` が必要:
```bash
npm install node-addon-api
```

### 4. TypeScriptラッパーの実装

**src/ym2151.ts**:
```typescript
// eslint-disable-next-line @typescript-eslint/no-var-requires
const addon = require('../build/Release/ym2151_addon.node');

export class YM2151 {
    private chip: any;

    constructor() {
        this.chip = new addon.YM2151();
    }

    reset(): void {
        this.chip.reset();
    }

    write(address: number, data: number): void {
        this.chip.write(address, data);
    }

    generateSamples(numFrames: number): Buffer {
        return this.chip.generateSamples(numFrames);
    }
}
```

### 5. 音声出力の実装

**src/audio.ts**:
```typescript
import Speaker from 'speaker';
import { Readable } from 'stream';

export class AudioPlayer {
    private speaker: Speaker;
    private sampleRate: number;

    constructor(sampleRate: number = 44100) {
        this.sampleRate = sampleRate;
        this.speaker = new Speaker({
            channels: 2,
            bitDepth: 16,
            sampleRate: sampleRate,
        });
    }

    play(buffer: Buffer): Promise<void> {
        return new Promise((resolve, reject) => {
            const stream = new Readable({
                read() {
                    this.push(buffer);
                    this.push(null);
                },
            });

            stream.pipe(this.speaker);

            this.speaker.on('close', () => resolve());
            this.speaker.on('error', (err) => reject(err));
        });
    }

    close(): void {
        this.speaker.end();
    }
}
```

### 6. メイン実装

**src/index.ts**:
```typescript
#!/usr/bin/env node
import { Command } from 'commander';
import { YM2151 } from './ym2151';
import { AudioPlayer } from './audio';

const program = new Command();

program
    .name('ym2151-emu')
    .description('YM2151 Emulator CLI')
    .option('-s, --sample-rate <rate>', 'Sample rate in Hz', '44100')
    .option('-d, --duration <seconds>', 'Duration in seconds', '5')
    .parse();

const options = program.opts();
const sampleRate = parseInt(options.sampleRate, 10);
const duration = parseInt(options.duration, 10);

async function main() {
    console.log('YM2151 Emulator starting...');
    console.log(`Sample rate: ${sampleRate} Hz`);
    console.log(`Duration: ${duration} seconds`);

    // YM2151の初期化
    const ym2151 = new YM2151();
    ym2151.reset();

    // デモ音声の設定（例: 440Hz正弦波）
    initDemoSound(ym2151);

    // サンプルの生成
    const numFrames = sampleRate * duration;
    console.log(`Generating ${numFrames} frames...`);
    const samples = ym2151.generateSamples(numFrames);

    // 音声の再生
    const player = new AudioPlayer(sampleRate);
    console.log('Playing audio...');
    await player.play(samples);
    player.close();

    console.log('Playback finished.');
}

function initDemoSound(ym2151: YM2151): void {
    // YM2151レジスタ設定でデモ音を設定
    // 例: 440Hz正弦波の設定
    // 実際のレジスタ値はYM2151のデータシートを参照
    ym2151.write(0x01, 0x02); // LFO設定など
    ym2151.write(0x08, 0x00); // Key on/off
    // ... 他のレジスタ設定
}

main().catch((err) => {
    console.error('Error:', err);
    process.exit(1);
});
```

## ビルド方法

### WSL2でのクロスコンパイル

TypeScript/Node.jsのクロスコンパイルは複雑です。以下の方法があります：

#### 方法1: GitHub Actions (推奨)

Windows環境で直接ビルド（後述のGitHub Actions参照）

#### 方法2: WSL2 + Wine (代替案)

```bash
# Node.jsのインストール
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 依存関係のインストール
cd src/typescript_node
npm install

# TypeScriptのビルド
npm run build

# Native Addonのビルド（Linux用）
npm run build

# pkgでパッケージング（Linux用バイナリが作成される）
npm run package
```

### ビルドスクリプト

**build.sh**:
```bash
#!/bin/bash
set -e

echo "Building YM2151 Emulator for Node.js..."

# 依存関係のインストール
npm install

# TypeScriptのビルド
echo "Compiling TypeScript..."
npx tsc

# Native Addonのビルド
echo "Building native addon..."
npx node-gyp rebuild

echo "Build completed!"
echo "Run with: node dist/index.js"
```

## テスト方法

### 開発環境でのテスト

```bash
# ビルド
npm run build

# 実行
npm start -- --duration 3
```

### ユニットテスト

**src/__tests__/ym2151.test.ts**:
```typescript
import { YM2151 } from '../ym2151';

describe('YM2151', () => {
    let ym2151: YM2151;

    beforeEach(() => {
        ym2151 = new YM2151();
    });

    test('should create instance', () => {
        expect(ym2151).toBeDefined();
    });

    test('should reset without error', () => {
        expect(() => ym2151.reset()).not.toThrow();
    });

    test('should generate samples', () => {
        ym2151.reset();
        const samples = ym2151.generateSamples(1024);
        expect(samples).toBeInstanceOf(Buffer);
        expect(samples.length).toBe(1024 * 2 * 2); // frames * channels * bytes_per_sample
    });
});
```

**package.json** にテストスクリプトを追加:
```json
{
  "scripts": {
    "test": "jest"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "@types/jest": "^29.0.0"
  }
}
```

実行:
```bash
npm test
```

## 実装優先度

1. **高**: 基本的なプロジェクト構造とビルドシステム
2. **高**: Node.js Native Addonの実装
3. **高**: 音声出力の基本実装
4. **中**: pkgでのパッケージング
5. **中**: デモ音声の実装（440Hz正弦波など）
6. **中**: コマンドライン引数の処理
7. **低**: エラーハンドリングの改善
8. **低**: ユニットテストの追加

## 技術的課題と対策

### 課題1: Native Addonのクロスコンパイル
- **対策**: GitHub ActionsでWindows環境を使用してビルド

### 課題2: speakerライブラリの依存関係
- **対策**: speakerはネイティブ依存があるため、pkgでバンドル時に注意

### 課題3: pkgでのNative Addon
- **対策**: `pkg-fetch`で適切なNode.jsバイナリを取得し、アドオンを同梱

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- speaker: https://github.com/TooTallNate/node-speaker
- node-addon-api: https://github.com/nodejs/node-addon-api
- Node.js N-API: https://nodejs.org/api/n-api.html
- pkg: https://github.com/vercel/pkg
