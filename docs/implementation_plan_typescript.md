# TypeScript/Node.js用ライブラリビルド計画書

## 概要

Nuked-OPMライブラリをWindows向けにビルドし、TypeScript/Node.jsからrequire()で利用可能なNative Addon (.node) を生成します。

## ビルド成果物

- **ファイル名**: `ym2151.node`
- **形式**: Node.js Native Addon
- **用途**: `const ym2151 = require('./ym2151.node')` でロード可能

## アーキテクチャ

```
src/typescript_node/
├── binding.gyp         # Node.js Native Addonビルド設定
├── package.json        # プロジェクト設定
├── ym2151.node         # 生成されるNative Addon（ビルド後）
├── src/
│   └── ym2151_addon.cc # Native Addon実装
└── vendor/
    └── nuked-opm/      # Nuked-OPMソースコード
        ├── opm.h
        └── opm.c
```

## 実装ステップ

### 1. プロジェクト初期化

```bash
cd src/typescript_node
npm init -y
npm install node-addon-api node-gyp
```

### 2. binding.gypの作成

**binding.gyp**:
```json
{
  "targets": [
    {
      "target_name": "ym2151",
      "sources": [
        "src/ym2151_addon.cc",
        "vendor/nuked-opm/opm.c"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")",
        "vendor/nuked-opm"
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

### 3. Native Addonの実装

**src/ym2151_addon.cc**:
```cpp
#include <napi.h>
extern "C" {
    #include "opm.h"
}

// YM2151をNode.jsから利用可能にするラッパー
class YM2151Wrapper : public Napi::ObjectWrap<YM2151Wrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports) {
        Napi::Function func = DefineClass(env, "YM2151", {
            InstanceMethod("reset", &YM2151Wrapper::Reset),
            InstanceMethod("write", &YM2151Wrapper::Write),
            InstanceMethod("clock", &YM2151Wrapper::Clock),
        });

        Napi::FunctionReference* constructor = new Napi::FunctionReference();
        *constructor = Napi::Persistent(func);
        env.SetInstanceData(constructor);

        exports.Set("YM2151", func);
        return exports;
    }

    YM2151Wrapper(const Napi::CallbackInfo& info) 
        : Napi::ObjectWrap<YM2151Wrapper>(info) {
        // チップの初期化
    }

private:
    opm_chip chip_;

    Napi::Value Reset(const Napi::CallbackInfo& info) {
        OPM_Reset(&chip_);
        return info.Env().Undefined();
    }

    Napi::Value Write(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        uint32_t address = info[0].As<Napi::Number>().Uint32Value();
        uint32_t data = info[1].As<Napi::Number>().Uint32Value();
        OPM_Write(&chip_, address, data);
        return env.Undefined();
    }

    Napi::Value Clock(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        uint32_t frames = info[0].As<Napi::Number>().Uint32Value();
        Napi::Buffer<int16_t> buffer = Napi::Buffer<int16_t>::New(env, frames * 2);
        OPM_Clock(&chip_, buffer.Data(), frames);
        return buffer;
    }
};

Napi::Object Init(Napi::Env env, Napi::Object exports) {
    return YM2151Wrapper::Init(env, exports);
}

NODE_API_MODULE(ym2151, Init)
```

## ビルド方法

### Windows環境でのビルド

```bash
# Node.jsのインストール（Windows）
# https://nodejs.org/

# 依存関係のインストール
cd src/typescript_node
npm install

# Native Addonのビルド
npx node-gyp rebuild

# 成果物の確認
ls build/Release/ym2151.node
```

### GitHub Actions (Windows環境)

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'

- name: Build Native Addon
  working-directory: src/typescript_node
  run: |
    npm install
    npx node-gyp rebuild
```

## テスト方法

### Node.jsからの利用例

```javascript
const ym2151 = require('./build/Release/ym2151.node');

// YM2151インスタンスの作成
const chip = new ym2151.YM2151();

// リセット
chip.reset();

// レジスタ書き込み
chip.write(0x01, 0x02);

// サンプル生成
const buffer = chip.clock(1024);
console.log('Generated', buffer.length, 'samples');
```

### TypeScriptからの利用

```typescript
// index.d.ts
declare module 'ym2151' {
    export class YM2151 {
        reset(): void;
        write(address: number, data: number): void;
        clock(frames: number): Buffer;
    }
}

// main.ts
import { YM2151 } from './build/Release/ym2151.node';

const chip = new YM2151();
chip.reset();
const samples = chip.clock(1024);
```

## 実装優先度

1. **高**: 基本的なbinding.gypとビルドシステム
2. **高**: Native Addonの実装
3. **高**: Nuked-OPMの統合
4. **中**: TypeScript型定義の作成
5. **低**: エラーハンドリングの追加

## 技術的課題と対策

### 課題1: Native Addonのクロスコンパイル
- **対策**: GitHub ActionsのWindows環境でビルド

### 課題2: mingw DLL依存
- **対策**: MSVCでビルドするか、MinGWの静的リンクオプションを使用

### 課題3: Node.jsバージョン互換性
- **対策**: node-addon-apiを使用してN-API互換を確保

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- node-addon-api: https://github.com/nodejs/node-addon-api
- Node.js N-API: https://nodejs.org/api/n-api.html
- node-gyp: https://github.com/nodejs/node-gyp
