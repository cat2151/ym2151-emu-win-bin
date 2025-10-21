# ライブラリ名変更に関する移行ガイド

## 変更の概要

このリポジトリが提供するライブラリ名を、公式Nuked-OPMであることを明確にするため変更しました。

### 変更内容

| 言語 | 旧ライブラリ名 | 新ライブラリ名 | 後方互換性 |
|------|--------------|--------------|----------|
| Rust | `libym2151.a` | `libnukedopm.a` | なし（新規ビルドのみ） |
| Rust | `ym2151.dll` | `nukedopm.dll` | なし（新規ビルドのみ） |
| Go | `libym2151.a` | `libnukedopm.a` | なし（新規ビルドのみ） |
| Python | `ym2151.dll` | `nukedopm.dll` | **あり**: `ym2151.dll`も提供 |

### 重要: APIは変更なし

**ライブラリ名が変更されただけで、APIは変更ありません**。

- すべてのライブラリは引き続き公式Nuked-OPM APIを提供します
- 関数名: `OPM_Reset()`, `OPM_Write()`, `OPM_Clock()` など（変更なし）
- 関数シグネチャ: opm.hと完全に一致（変更なし）

---

## 移行方法

### Python（後方互換性あり）

Pythonの場合、`ym2151.dll` は引き続き提供されるため、**コード変更は不要**です。

ただし、新しいプロジェクトでは `nukedopm.dll` の使用を推奨します：

```python
# 旧（引き続き動作します）
lib = ctypes.CDLL('./ym2151.dll')

# 新（推奨）
lib = ctypes.CDLL('./nukedopm.dll')

# APIは同じ
lib.OPM_Reset.argtypes = [ctypes.POINTER(opm_t)]
lib.OPM_Write.argtypes = [ctypes.POINTER(opm_t), ctypes.c_uint32, ctypes.c_uint8]
# ...
```

### Rust

Rustプロジェクトで当リポジトリのライブラリを使用している場合：

#### Cargo.tomlでのリンク指定

```toml
# 旧
[dependencies]
# ...

[build-dependencies]
# ...

# build.rsまたはリンカ設定で -lym2151 を指定していた場合

# 新
# build.rsまたはリンカ設定で -lnukedopm に変更
```

#### extern "C" 宣言

extern "C" 宣言は変更不要です（公式APIのまま）：

```rust
extern "C" {
    // 変更不要: 公式Nuked-OPM API
    fn OPM_Reset(chip: *mut opm_t);
    fn OPM_Write(chip: *mut opm_t, port: u32, data: u8);
    fn OPM_Clock(chip: *mut opm_t, output: *mut i32, sh1: *mut u8, sh2: *mut u8, so: *mut u8);
}
```

### Go

GoプロジェクトでCGO経由で使用している場合：

```go
// 旧
/*
#cgo LDFLAGS: -L/path/to -lym2151
#include "vendor/nuked-opm/opm.h"
*/

// 新
/*
#cgo LDFLAGS: -L/path/to -lnukedopm
#include "vendor/nuked-opm/opm.h"
*/

// APIは変更なし（公式Nuked-OPM API）
var chip C.opm_t
C.OPM_Reset(&chip)
```

---

## なぜ名前を変更したのか？

### 問題点

1. **出所が不明瞭**: `ym2151.dll` という名前では、どのエミュレータライブラリかが分からない
   - YM2151エミュレータは複数存在（Nuked-OPM、ymfm、その他）
   - ユーザーが混乱する可能性

2. **カスタムラッパーと誤解される**: 
   - 実際には公式Nuked-OPM APIをそのまま提供している
   - ライブラリ名が異なるため、ラッパーと誤解される

3. **公式ドキュメントとの乖離**:
   - ユーザーは公式Nuked-OPMのドキュメントを参照できるはず
   - しかし名前が違うため混乱を招く

### 解決策

- ライブラリ名を `nukedopm` に変更
- ドキュメントで「公式Nuked-OPM APIを提供」と明記
- ユーザーは公式opm.hを参照できる

---

## よくある質問

### Q: 既存のプロジェクトは動き続けますか？

**A**: Pythonは引き続き動作します（`ym2151.dll` を提供）。RustとGoは新しいライブラリ名に変更が必要です。

### Q: APIは変更されますか？

**A**: いいえ。APIは公式Nuked-OPMのままで、変更ありません。

### Q: いつから変更されますか？

**A**: 次回のビルドから新しいライブラリ名が使用されます。Pythonは後方互換性のため `ym2151.dll` も引き続き提供されます。

### Q: 公式Nuked-OPMのドキュメントをそのまま使えますか？

**A**: はい。すべてのライブラリは公式Nuked-OPM APIをそのまま提供しているため、公式リポジトリの opm.h を参照できます。
https://github.com/nukeykt/Nuked-OPM/blob/master/opm.h

---

## サポート

問題がある場合は、以下を確認してください：

1. **APIは変更されていない**: 関数名、シグネチャはopm.hと同じです
2. **リンク時のライブラリ名のみ変更**: `-lym2151` → `-lnukedopm`
3. **Pythonは後方互換性あり**: `ym2151.dll` は引き続き使用可能

それでも問題がある場合は、Issueを作成してください。
