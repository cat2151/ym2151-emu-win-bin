# Go Nuked-OPM Library

公式Nuked-OPM (https://github.com/nukeykt/Nuked-OPM) をWindows向けにビルドし、GoプロジェクトからCGO経由で利用可能な静的ライブラリを生成します。

## 重要: このライブラリについて

このライブラリは**公式Nuked-OPMのビルド成果物**であり、カスタムラッパーではありません。
すべての関数は公式opm.hで定義されているものと同じシグネチャで提供されます。

## ビルド方法

```bash
# リポジトリのルートから実行
bash scripts/build_go.sh
```

このスクリプトは以下を実行します：
1. Nuked-OPMをvendor/nuked-opmにクローン（未取得の場合）
2. Makefileを使用してlibnukedopm.aをビルド

## 成果物

- `libnukedopm.a` - 静的ライブラリ

**注意**: ライブラリ名は `nukedopm` ですが、エクスポートされる関数は公式の `OPM_*` です。

## 前提条件

- mingw-w64 (`x86_64-w64-mingw32-gcc`, `x86_64-w64-mingw32-ar`)
- make

## 利用方法（公式API）

GoからCGO経由で公式Nuked-OPM APIを使用：

```go
package main

/*
#cgo CFLAGS: -I/path/to/nukedopm/vendor/nuked-opm
#cgo LDFLAGS: -L/path/to/nukedopm -lnukedopm -static
#include "vendor/nuked-opm/opm.h"
*/
import "C"
import "unsafe"

func main() {
    // 公式Nuked-OPM APIを使用
    var chip C.opm_t
    C.OPM_Reset(&chip)
    
    // レジスタへの書き込み
    C.OPM_Write(&chip, 0, 0x20)  // address
    C.OPM_Write(&chip, 1, 0xC0)  // data
    
    // サンプル生成
    var output [2]C.int
    var sh1, sh2, so C.uchar
    C.OPM_Clock(&chip, (*C.int)(unsafe.Pointer(&output[0])), &sh1, &sh2, &so)
}
```

詳細なAPIドキュメントは公式リポジトリを参照：
https://github.com/nukeykt/Nuked-OPM/blob/master/opm.h
