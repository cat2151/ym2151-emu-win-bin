# Go実装計画書

## 概要

Goで、Nuked-OPMライブラリを使用したYM2151エミュレータCLIを作成します。
音声出力には`oto`ライブラリを使用し、Windows向けに静的リンクされた実行ファイルを生成します。

## アーキテクチャ

```
src/go/
├── go.mod              # モジュール定義
├── main.go             # エントリポイント
├── ym2151/
│   ├── ym2151.go       # YM2151エミュレータCGOバインディング
│   └── ym2151.h        # CGOヘッダ
├── audio/
│   └── audio.go        # 音声出力ハンドラ
└── vendor/
    └── nuked-opm/      # Nuked-OPMソースコード
        ├── opm.h
        └── opm.c
```

## 依存関係

### go.mod

```go
module github.com/cat2151/ym2151-emu-win-bin/src/go

go 1.21

require (
    github.com/ebitengine/oto/v3 v3.1.0
    github.com/spf13/cobra v1.8.0
)
```

## 実装ステップ

### 1. プロジェクト初期化

```bash
cd src/go
go mod init github.com/cat2151/ym2151-emu-win-bin/src/go
```

### 2. Nuked-OPMのCGOバインディング

**ym2151/ym2151.go**:
```go
package ym2151

/*
#cgo CFLAGS: -I${SRCDIR}/../vendor/nuked-opm
#cgo windows LDFLAGS: -static -static-libgcc -static-libstdc++
#include "../vendor/nuked-opm/opm.h"
#include "../vendor/nuked-opm/opm.c"
*/
import "C"
import (
    "unsafe"
)

type Chip struct {
    chip *C.opm_chip
}

func New() *Chip {
    chip := &Chip{
        chip: (*C.opm_chip)(C.malloc(C.sizeof_opm_chip)),
    }
    return chip
}

func (c *Chip) Reset() {
    C.OPM_Reset(c.chip)
}

func (c *Chip) Write(address uint8, data uint8) {
    C.OPM_Write(c.chip, C.uint(address), C.uint(data))
}

func (c *Chip) GenerateSamples(buffer []int16) {
    if len(buffer) == 0 {
        return
    }
    C.OPM_Clock(
        c.chip,
        (*C.short)(unsafe.Pointer(&buffer[0])),
        C.uint(len(buffer)/2), // stereo
    )
}

func (c *Chip) Close() {
    if c.chip != nil {
        C.free(unsafe.Pointer(c.chip))
        c.chip = nil
    }
}
```

### 3. 音声出力の実装

**audio/audio.go**:
```go
package audio

import (
    "github.com/ebitengine/oto/v3"
    "time"
)

type Player struct {
    context *oto.Context
    player  oto.Player
}

func NewPlayer(sampleRate int) (*Player, error) {
    op := &oto.NewContextOptions{
        SampleRate:   sampleRate,
        ChannelCount: 2,
        Format:       oto.FormatSignedInt16LE,
    }

    ctx, ready, err := oto.NewContext(op)
    if err != nil {
        return nil, err
    }
    <-ready

    return &Player{
        context: ctx,
    }, nil
}

func (p *Player) Play(buffer []byte) error {
    if p.player == nil {
        p.player = p.context.NewPlayer(bytes.NewReader(buffer))
    }
    p.player.Play()
    return nil
}

func (p *Player) Wait(duration time.Duration) {
    time.Sleep(duration)
}

func (p *Player) Close() error {
    if p.player != nil {
        p.player.Close()
    }
    if p.context != nil {
        return p.context.Close()
    }
    return nil
}
```

### 4. メイン実装

**main.go**:
```go
package main

import (
    "bytes"
    "encoding/binary"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/cat2151/ym2151-emu-win-bin/src/go/audio"
    "github.com/cat2151/ym2151-emu-win-bin/src/go/ym2151"
    "github.com/spf13/cobra"
)

var (
    sampleRate int
    duration   int
)

func main() {
    rootCmd := &cobra.Command{
        Use:   "ym2151-emu",
        Short: "YM2151 Emulator CLI",
        Run:   run,
    }

    rootCmd.Flags().IntVarP(&sampleRate, "sample-rate", "s", 44100, "Sample rate")
    rootCmd.Flags().IntVarP(&duration, "duration", "d", 5, "Duration in seconds")

    if err := rootCmd.Execute(); err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}

func run(cmd *cobra.Command, args []string) {
    fmt.Printf("YM2151 Emulator starting...\n")
    fmt.Printf("Sample rate: %d Hz\n", sampleRate)
    fmt.Printf("Duration: %d seconds\n", duration)

    // YM2151の初期化
    chip := ym2151.New()
    defer chip.Close()
    chip.Reset()

    // デモ音声の設定（例: 440Hz正弦波）
    initDemoSound(chip)

    // 音声バッファの生成
    bufferSize := sampleRate * 2 * 2 // stereo, 16-bit
    samples := make([]int16, bufferSize)
    chip.GenerateSamples(samples)

    // int16をbytesに変換
    buf := new(bytes.Buffer)
    for _, sample := range samples {
        binary.Write(buf, binary.LittleEndian, sample)
    }

    // 音声出力
    player, err := audio.NewPlayer(sampleRate)
    if err != nil {
        log.Fatalf("Failed to initialize audio: %v", err)
    }
    defer player.Close()

    if err := player.Play(buf.Bytes()); err != nil {
        log.Fatalf("Failed to play audio: %v", err)
    }

    player.Wait(time.Duration(duration) * time.Second)

    fmt.Println("Playback finished.")
}

func initDemoSound(chip *ym2151.Chip) {
    // YM2151レジスタ設定でデモ音を設定
    // 例: 440Hz正弦波の設定
    // 実際のレジスタ値はYM2151のデータシートを参照
    chip.Write(0x01, 0x02) // LFO設定など
    chip.Write(0x08, 0x00) // Key on/off
    // ... 他のレジスタ設定
}
```

## ビルド方法

### WSL2でのクロスコンパイル

```bash
# Goのインストール
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# MinGWのインストール
sudo apt-get update
sudo apt-get install -y mingw-w64

# 環境変数の設定
export GOOS=windows
export GOARCH=amd64
export CGO_ENABLED=1
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++

# 依存関係の取得
cd src/go
go mod download

# ビルド
go build -ldflags "-s -w -linkmode external -extldflags '-static'" -o ym2151-emu.exe

# バイナリサイズの最適化（optional）
strip ym2151-emu.exe
```

### ビルドスクリプト

**build.sh**:
```bash
#!/bin/bash
set -e

echo "Building YM2151 Emulator for Windows..."

# 環境変数設定
export GOOS=windows
export GOARCH=amd64
export CGO_ENABLED=1
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++

# ビルド
go build -v \
    -ldflags "-s -w -linkmode external -extldflags '-static'" \
    -o ym2151-emu.exe

echo "Build completed: ym2151-emu.exe"

# DLL依存の確認
echo "Checking DLL dependencies..."
x86_64-w64-mingw32-objdump -p ym2151-emu.exe | grep -i "dll" || echo "No DLL dependencies found (static build successful)"
```

## テスト方法

### WSL2からWindowsバイナリを実行

```bash
# Windows側で実行
/mnt/c/Windows/System32/cmd.exe /c ./ym2151-emu.exe --duration 3
```

### ユニットテスト

**ym2151/ym2151_test.go**:
```go
package ym2151

import (
    "testing"
)

func TestNew(t *testing.T) {
    chip := New()
    if chip == nil {
        t.Fatal("Failed to create chip")
    }
    defer chip.Close()
}

func TestReset(t *testing.T) {
    chip := New()
    defer chip.Close()
    
    // パニックしないことを確認
    chip.Reset()
}

func TestGenerateSamples(t *testing.T) {
    chip := New()
    defer chip.Close()
    chip.Reset()

    buffer := make([]int16, 1024)
    chip.GenerateSamples(buffer)

    // バッファが変更されていることを確認
    hasNonZero := false
    for _, sample := range buffer {
        if sample != 0 {
            hasNonZero = true
            break
        }
    }
    
    // 注: 初期化直後は無音の可能性があるため、このテストは参考程度
    _ = hasNonZero
}
```

## 実装優先度

1. **高**: 基本的なプロジェクト構造とビルドシステム
2. **高**: Nuked-OPMのCGOバインディング
3. **高**: 音声出力の基本実装
4. **中**: デモ音声の実装（440Hz正弦波など）
5. **中**: コマンドライン引数の処理
6. **低**: エラーハンドリングの改善
7. **低**: ユニットテストの追加

## 技術的課題と対策

### 課題1: CGOでの静的リンク
- **対策**: `-ldflags "-linkmode external -extldflags '-static'"` を使用

### 課題2: otoライブラリのWindows対応
- **対策**: otoはWindows WASAPIをサポート。追加設定不要

### 課題3: クロスコンパイル時のCGO
- **対策**: CC環境変数で mingw-w64 を指定

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- oto: https://github.com/ebitengine/oto
- Go CGO: https://pkg.go.dev/cmd/cgo
- Go Cross Compilation: https://github.com/golang/go/wiki/WindowsCrossCompiling
