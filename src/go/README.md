# Go YM2151 Library

Nuked-OPMライブラリをWindows向けにビルドし、GoプロジェクトからCGO経由で利用可能な静的ライブラリを生成します。

## ビルド方法

```bash
# リポジトリのルートから実行
bash scripts/build_go.sh
```

このスクリプトは以下を実行します：
1. Nuked-OPMをvendor/nuked-opmにクローン（未取得の場合）
2. Makefileを使用してlibym2151.aをビルド

## 成果物

- `libym2151.a` - 静的ライブラリ

## 前提条件

- mingw-w64 (`x86_64-w64-mingw32-gcc`, `x86_64-w64-mingw32-ar`)
- make

## 利用方法

GoからCGO経由で利用：

```go
package main

/*
#cgo CFLAGS: -I/path/to/ym2151
#cgo LDFLAGS: -L/path/to/ym2151 -lym2151 -static
#include "ym2151.h"
*/
import "C"

func main() {
    // YM2151ライブラリの利用
}
```
