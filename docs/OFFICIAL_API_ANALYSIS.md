# Nuked-OPM公式APIと現在の実装の比較分析

## 作成日
2025-10-21

## 目的
このドキュメントは、公式Nuked-OPMライブラリと当リポジトリの実装を比較し、wrappingが必要かどうかを明確にするために作成されました。

---

## 公式Nuked-OPMが提唱しているもの

### リポジトリ
https://github.com/nukeykt/Nuked-OPM

### 提供されるファイル
- `opm.h` - ヘッダファイル
- `opm.c` - 実装ファイル

### 公式APIシグネチャ (opm.h より)

```c
// チップ状態を表す構造体
typedef struct {
    uint32_t cycles;
    uint8_t ic;
    // ... 多数のフィールド（約2KB以上）
} opm_t;

// 公式関数
void OPM_Clock(opm_t *chip, int32_t *output, uint8_t *sh1, uint8_t *sh2, uint8_t *so);
void OPM_Write(opm_t *chip, uint32_t port, uint8_t data);
uint8_t OPM_Read(opm_t *chip, uint32_t port);
uint8_t OPM_ReadIRQ(opm_t *chip);
uint8_t OPM_ReadCT1(opm_t *chip);
uint8_t OPM_ReadCT2(opm_t *chip);
void OPM_SetIC(opm_t *chip, uint8_t ic);
void OPM_Reset(opm_t *chip);
```

### 公式の使い方

1. `opm_t` 構造体を宣言
2. `OPM_Reset()` で初期化
3. `OPM_Write()` でレジスタに書き込み
4. `OPM_Clock()` を呼び出して音声サンプルを生成

### 公式のライブラリ名
Nuked-OPMは**ライブラリ名を指定していない**。ユーザーが自分でビルドして名前を付ける。
ただし、一般的には以下のような名前が使われる：
- `libnukedopm.a` (静的ライブラリ)
- `libnukedopm.dll` / `libnukedopm.so` (動的ライブラリ)

---

## 当リポジトリの現在の実装

### Rust実装 (`src/rust/src/lib.rs`)

```rust
use std::os::raw::c_uint;

#[repr(C)]
pub struct OpmChip {
    _private: [u8; 0],
}

extern "C" {
    pub fn OPM_Reset(chip: *mut OpmChip);
    pub fn OPM_Write(chip: *mut OpmChip, port: c_uint, data: c_uint);
    pub fn OPM_Clock(chip: *mut OpmChip, buffer: *mut i16, frames: c_uint);
}

// このライブラリは他の言語から利用されることを想定
// Rustから使う場合のラッパーは別途実装可能
```

**問題点**:
1. ❌ `OPM_Clock()` のシグネチャが**間違っている**
   - 公式: `void OPM_Clock(opm_t *chip, int32_t *output, uint8_t *sh1, uint8_t *sh2, uint8_t *so);`
   - 現在: `pub fn OPM_Clock(chip: *mut OpmChip, buffer: *mut i16, frames: c_uint);`
   - `sh1`, `sh2`, `so` パラメータが欠落
   - `buffer` は `int32_t *` であるべきなのに `i16 *` になっている

2. ❌ 構造体の型が異なる
   - 公式: `opm_t` (具体的な構造体定義あり)
   - 現在: `OpmChip` (不透明型)

3. ✅ 関数名は公式と一致している

### Go実装 (`src/go/ym2151.h`)

```c
#ifndef YM2151_H
#define YM2151_H

#include "vendor/nuked-opm/opm.h"

// 必要に応じて追加の関数を定義

#endif // YM2151_H
```

**評価**:
✅ 公式の `opm.h` をそのままインクルードしている - これは正しいアプローチ

### Python実装 (`src/python/Makefile`)

```makefile
CC = x86_64-w64-mingw32-gcc
CFLAGS = -O3 -Wall -shared -static-libgcc -static-libstdc++
TARGET = ym2151.dll
SOURCES = vendor/nuked-opm/opm.c
```

**評価**:
- ✅ 公式の `opm.c` を直接コンパイルしている
- ❌ ライブラリ名が `ym2151.dll` - 公式を示す名前ではない
- ✅ 関数はすべて公式のものがそのままエクスポートされる

---

## ym2151-emulator-examplesでの使用状況

### Python版での使用 (`nuked_opm.py` より)

```python
# ライブラリのロード
_lib_name = 'ym2151.dll'  # ← 当リポジトリが提供
_lib = ctypes.CDLL(_lib_path)

# 公式APIを直接使用
_lib.OPM_Reset.argtypes = [ctypes.POINTER(OPM_t)]
_lib.OPM_Write.argtypes = [ctypes.POINTER(OPM_t), ctypes.c_uint32, ctypes.c_uint8]
_lib.OPM_Clock.argtypes = [
    ctypes.POINTER(OPM_t),
    ctypes.POINTER(ctypes.c_int32),  # int32_t *output
    ctypes.POINTER(ctypes.c_uint8),  # uint8_t *sh1
    ctypes.POINTER(ctypes.c_uint8),  # uint8_t *sh2
    ctypes.POINTER(ctypes.c_uint8)   # uint8_t *so
]
```

**重要**: 
- ユーザーは公式の `OPM_*` 関数を期待している
- ライブラリ名 `ym2151.dll` はファイル名の問題だけで、APIは公式を使用

### Rust版での使用 (`main.rs` より)

```rust
extern "C" {
    fn OPM_Clock(
        chip: *mut OpmChip,
        output: *mut i32,      // ← 正しい: int32_t *
        sh1: *mut u8,          // ← 正しい: uint8_t *
        sh2: *mut u8,          // ← 正しい
        so: *mut u8,           // ← 正しい
    );
    fn OPM_Write(chip: *mut OpmChip, port: u32, data: u8);
    fn OPM_Reset(chip: *mut OpmChip);
}
```

**重要**:
- ユーザーは**正しい公式APIシグネチャ**を使用している
- 当リポジトリの `src/rust/src/lib.rs` のシグネチャとは**異なる**

---

## 問題点の整理

### 1. Rustの `lib.rs` が公式APIと異なる ❌

当リポジトリの `src/rust/src/lib.rs` で定義している `OPM_Clock()` が、公式と異なるシグネチャになっている。

**影響**: 
- ユーザーが当リポジトリのRustライブラリを使おうとすると、正しく動作しない可能性がある
- 実際には `build.rs` で直接 `opm.c` をコンパイルしているので、正しい関数がリンクされるが、`lib.rs` の宣言が誤解を招く

### 2. ライブラリ名が公式を示していない ⚠️

- `ym2151.dll` という名前は、どのエミュレータライブラリかが不明
- `libnukedopm.dll` や `nukedopm.dll` の方が分かりやすい

**影響**:
- ユーザーがライブラリの出所を理解しにくい
- 他のYM2151エミュレータ（ymfmなど）と区別がつきにくい

### 3. 不要なwrapper ❌

`src/rust/src/lib.rs` は、実際には何もwrapしていない（すべきでない）：
- `extern "C"` で公式関数を宣言しているだけ
- これらの関数は `build.rs` でコンパイルされた `opm.c` から来る
- わざわざ `lib.rs` で再宣言する必要はない

---

## 修正すべきこと

### 1. Rustの `lib.rs` を修正または削除

**オプションA: 正しいシグネチャに修正**
```rust
extern "C" {
    pub fn OPM_Clock(
        chip: *mut opm_t,
        output: *mut i32,
        sh1: *mut u8,
        sh2: *mut u8,
        so: *mut u8,
    );
    pub fn OPM_Write(chip: *mut opm_t, port: u32, data: u8);
    pub fn OPM_Reset(chip: *mut opm_t);
    // ... 他の公式関数も追加
}
```

**オプションB: `lib.rs` を削除して、静的ライブラリのみ提供**
- `Cargo.toml` の `crate-type` から `cdylib` を削除
- `lib.rs` を削除
- 静的ライブラリ (`.a`) のみを提供

### 2. ライブラリ名を変更

| 言語 | 現在 | 推奨 |
|------|------|------|
| Rust | `libym2151.a`, `ym2151.dll` | `libnukedopm.a`, `nukedopm.dll` |
| Go | `libym2151.a` | `libnukedopm.a` |
| Python | `ym2151.dll` | `nukedopm.dll` |

**ただし注意**: 
- ym2151-emulator-examplesは既に `ym2151.dll` を使用している
- 名前を変更すると、既存ユーザーへの影響がある
- **代替案**: ドキュメントで「このライブラリはNuked-OPMの公式APIを提供している」と明記

### 3. ドキュメントの明確化

READMEやドキュメントに以下を明記：
- このリポジトリが提供するライブラリは、Nuked-OPMの**公式API**をそのまま提供している
- wrapperやカスタムAPIは存在しない
- 関数名、シグネチャはすべて公式Nuked-OPMと同一
- ライブラリ名は便宜的に `ym2151.dll` などとしているが、中身は純粋なNuked-OPM

---

## 推奨される対応方針

### 最小限の変更で対応（推奨）

1. **Rustの `lib.rs` を削除または最小化**
   - 不要なwrapper宣言を削除
   - または、公式と同じシグネチャに修正
   - コメントで「公式Nuked-OPM APIをそのまま提供」と明記

2. **ドキュメントを充実**
   - 各言語のREADMEに「公式Nuked-OPM APIを提供」と明記
   - 関数シグネチャは https://github.com/nukeykt/Nuked-OPM/blob/master/opm.h を参照するよう案内

3. **ライブラリ名は現状維持**
   - 既存ユーザーへの影響を避けるため
   - ただし、ドキュメントで「中身はNuked-OPM」と明記

### より良い対応（将来的に検討）

1. **ライブラリ名を変更**
   - `ym2151.dll` → `nukedopm.dll`
   - 既存ユーザーには移行ガイドを提供

2. **複数のエミュレータをサポート**
   - Nuked-OPM: `nukedopm.dll`
   - ymfm: `ymfm.dll`
   - それぞれ公式APIをそのまま提供

---

## 結論

**現状の問題**:
- Rustの `lib.rs` で間違ったシグネチャを宣言している
- 「wrapper」という表現が誤解を招いている（実際にはwrapしていない）
- ライブラリ名が出所を示していない

**解決策**:
1. `lib.rs` の修正または削除（wrappingは不要）
2. ドキュメントで「公式Nuked-OPM APIを提供」と明確化
3. 必要に応じてライブラリ名の変更を検討

**公式との関係**:
- 当リポジトリは、公式Nuked-OPMをWindows向けにビルドして提供しているだけ
- カスタムAPIやwrapperは不要（現在も実質的には提供していない）
- ユーザーは公式Nuked-OPM APIをそのまま使える
