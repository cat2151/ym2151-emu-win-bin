# Go用ライブラリビルド計画書

## 概要

Nuked-OPMライブラリをWindows向けにビルドし、GoプロジェクトからCGO経由で利用可能な静的ライブラリ (.a) を生成します。

## ビルド成果物

- **ファイル名**: `libym2151.a`
- **形式**: 静的ライブラリ
- **用途**: GoのCGOから `#cgo LDFLAGS: -L. -lym2151` でリンク可能

## アーキテクチャ

```
src/go/
├── Makefile            # ビルド用Makefile
├── ym2151.h            # ヘッダファイル
├── libym2151.a         # 生成されるライブラリ（ビルド後）
└── vendor/
    └── nuked-opm/      # Nuked-OPMソースコード
        ├── opm.h
        └── opm.c
```

## 実装ステップ

### 1. プロジェクト初期化

```bash
cd src/go
mkdir -p vendor
git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
```

### 2. ヘッダファイルの作成

**ym2151.h** (Nuked-OPMのラッパー):
```c
#ifndef YM2151_H
#define YM2151_H

#include "vendor/nuked-opm/opm.h"

// 必要に応じて追加の関数を定義

#endif // YM2151_H
```

### 3. Makefileの作成

**Makefile**:
```makefile
CC = x86_64-w64-mingw32-gcc
AR = x86_64-w64-mingw32-ar
CFLAGS = -O3 -Wall -static-libgcc
TARGET = libym2151.a
SOURCES = vendor/nuked-opm/opm.c
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(AR) rcs $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all clean
```

## ビルド方法

### WSL2でのクロスコンパイル

```bash
# MinGWのインストール
sudo apt-get update
sudo apt-get install -y mingw-w64

# ビルド
cd src/go
make

# 成果物の確認
ls -lh libym2151.a
```

### 静的リンク確認

```bash
# シンボルの確認
x86_64-w64-mingw32-nm libym2151.a | grep OPM

# ライブラリ情報の確認
file libym2151.a
```

## テスト方法

### GoからのCGO利用例

```go
package main

/*
#cgo CFLAGS: -I.
#cgo LDFLAGS: -L. -lym2151 -static -static-libgcc
#include "ym2151.h"
*/
import "C"
import "fmt"

func main() {
    fmt.Println("YM2151 library loaded successfully")
    // Nuked-OPM関数の呼び出しテスト
}
```

### ビルドテスト

```bash
# Go環境変数の設定
export GOOS=windows
export GOARCH=amd64
export CGO_ENABLED=1
export CC=x86_64-w64-mingw32-gcc

# テストプログラムのビルド
go build -o test.exe test.go
```

## 利用例

### Goプロジェクトから利用

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

## 実装優先度

1. **高**: 基本的なMakefileとビルドシステム
2. **高**: Nuked-OPMの静的ライブラリとしてのコンパイル
3. **中**: ヘッダファイルの整備
4. **低**: ビルドスクリプトの自動化

## 技術的課題と対策

### 課題1: CGOでの静的リンク
- **対策**: `-static-libgcc` フラグでmingw DLL依存を回避

### 課題2: クロスコンパイル
- **対策**: mingw-w64で直接Windowsライブラリを生成

### 課題3: シンボルの可視性
- **対策**: デフォルトでエクスポートされる。必要に応じて `.def` ファイルで制御

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- Go CGO: https://pkg.go.dev/cmd/cgo
- MinGW-w64: https://www.mingw-w64.org/
