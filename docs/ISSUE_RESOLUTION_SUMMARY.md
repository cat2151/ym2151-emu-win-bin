# Issue解決サマリー: ライブラリの呼び出しや名称についてwrappingをやめ、公式が提唱しているものに修正する

## 作成日
2025-10-21

## 問題提起への回答

### 1. 公式が提唱しているライブラリ名は？

**回答**: Nuked-OPMは**ライブラリ名を指定していません**。

- 公式リポジトリ: https://github.com/nukeykt/Nuked-OPM
- 提供ファイル: `opm.h` (ヘッダ), `opm.c` (実装)
- ユーザーが自分でビルドして任意の名前を付けることを想定

一般的に使われる名前の例：
- `libnukedopm.a` (静的ライブラリ)
- `libnukedopm.so` / `libnukedopm.dll` (動的ライブラリ)
- `nukedopm.lib` (Windows静的ライブラリ)

### 2. 公式の関数シグネチャは？

**回答**: opm.hで定義されている公式APIは以下の通り：

```c
// チップ状態構造体
typedef struct {
    uint32_t cycles;
    uint8_t ic;
    // ... その他多数のフィールド（約2KB以上）
} opm_t;

// 公式関数
void OPM_Reset(opm_t *chip);
void OPM_Write(opm_t *chip, uint32_t port, uint8_t data);
void OPM_Clock(opm_t *chip, int32_t *output, uint8_t *sh1, uint8_t *sh2, uint8_t *so);
uint8_t OPM_Read(opm_t *chip, uint32_t port);
uint8_t OPM_ReadIRQ(opm_t *chip);
uint8_t OPM_ReadCT1(opm_t *chip);
uint8_t OPM_ReadCT2(opm_t *chip);
void OPM_SetIC(opm_t *chip, uint8_t ic);
```

詳細: https://github.com/nukeykt/Nuked-OPM/blob/master/opm.h

### 3. 公式はどのようにして使うことを表明している？

**回答**: 公式ドキュメントは最小限だが、使い方は明確：

1. `opm_t` 構造体を宣言（または動的割り当て）
2. `OPM_Reset(chip)` で初期化
3. `OPM_Write(chip, port, data)` でレジスタに書き込み
   - `port=0`: アドレス書き込み
   - `port=1`: データ書き込み
4. `OPM_Clock(chip, output, sh1, sh2, so)` を繰り返し呼び出してサンプル生成
   - YM2151は約3.58MHzで動作
   - 1サンプル生成に複数回のクロックが必要

**公式の使用例は提供されていませんが**、opm.hのコメントとコードから明らか。

---

## なぜ当リポジトリは違うライブラリ名（ym2151.dll）や違う関数シグネチャにしていたのか？

### 問題点1: ライブラリ名が `ym2151.dll` / `libym2151.a` だった

**理由**（推測）:
- Nuked-OPMが公式ライブラリ名を指定していないため、独自に命名
- YM2151チップ名から単純に命名
- 特に深い意図はなかった可能性

**問題**:
- どのエミュレータライブラリか不明瞭（Nuked-OPM? ymfm? その他？）
- 公式を示す名前ではない
- ラッパーと誤解される可能性

### 問題点2: Rustの `lib.rs` で間違った関数シグネチャを宣言していた

**現状の問題**（修正前）:
```rust
// src/rust/src/lib.rs の旧実装
extern "C" {
    pub fn OPM_Clock(chip: *mut OpmChip, buffer: *mut i16, frames: c_uint);
    //                                            ^^^^^^         ^^^^^^
    //                                            間違い          間違い
}
```

**公式の正しいシグネチャ**:
```c
void OPM_Clock(opm_t *chip, int32_t *output, uint8_t *sh1, uint8_t *sh2, uint8_t *so);
```

**理由**（推測）:
- 簡略化しようとした？
- 複数サンプルを一度に生成しようとした？
- 公式APIを誤解していた

**問題**:
- ユーザーが正しく使えない
- 公式ドキュメントと合わない
- ym2151-emulator-examplesの使い方と異なる

### 問題点3: 「wrapper」という誤解を招く表現

**現状**:
- ドキュメントやコードに「wrapper」という表現
- 実際には何もwrapしていない（公式opm.cをそのままコンパイル）

**問題**:
- カスタムAPIを提供していると誤解される
- 実際には公式APIをそのまま提供しているだけ

---

## 公式と同じにできない理由は？ → できます！

**回答: できます。実際、すでにそうなっていました。**

### 実態

1. **Go実装**: すでに公式APIをそのまま提供
   - `src/go/ym2151.h` は公式 `opm.h` をインクルード
   - 何もwrapしていない

2. **Python実装**: すでに公式APIをそのまま提供
   - Makefileで公式 `opm.c` を直接コンパイル
   - 関数は公式のものがそのままエクスポート

3. **Rust実装**: build.rsで公式をビルドしているが、lib.rsの宣言が間違っていた
   - `build.rs` で公式 `opm.c` をコンパイル（正しい）
   - `lib.rs` で間違ったシグネチャを宣言（問題）

### つまり

- **Build側**: すでに公式をそのままビルドしていた ✅
- **問題点**: ライブラリ名とドキュメントが誤解を招いていた ❌
- **Rustのみ**: lib.rsの宣言が間違っていた ❌

---

## 修正内容

### 1. ライブラリ名を変更

| 言語 | 旧 | 新 |
|------|----|----|
| Rust | `libym2151.a` / `ym2151.dll` | `libnukedopm.a` / `nukedopm.dll` |
| Go | `libym2151.a` | `libnukedopm.a` |
| Python | `ym2151.dll` | `nukedopm.dll` + `ym2151.dll`(legacy) |

### 2. Rustの `lib.rs` を修正

**修正前**（問題のあるコード）:
```rust
extern "C" {
    pub fn OPM_Clock(chip: *mut OpmChip, buffer: *mut i16, frames: c_uint);
}
```

**修正後**（ドキュメントのみに変更）:
```rust
// このライブラリは公式Nuked-OPMを提供します
// 公式APIの使い方はopm.hを参照してください
// 
// 関数はbuild.rsでコンパイルされるopm.cから提供されます
```

→ lib.rsでの宣言は不要（ユーザーが自分で宣言する）

### 3. ドキュメントを充実

- **OFFICIAL_API_ANALYSIS.md**: 公式APIとの詳細比較
- **MIGRATION_GUIDE.md**: 移行ガイド
- すべてのREADMEを更新: 「公式Nuked-OPM APIを提供」と明記

### 4. GitHub Actionsを更新

- ビルド成果物の名前を新しいライブラリ名に変更
- Pythonは後方互換性のため両方をコミット

---

## 結論

### 質問への最終回答

1. **公式が提唱しているライブラリ名は？**
   → 特に指定なし。一般的に `libnukedopm.*` が使われる

2. **公式の関数シグネチャは？**
   → `OPM_Reset()`, `OPM_Write()`, `OPM_Clock()` など（opm.h参照）

3. **公式はどのように使うことを表明している？**
   → opm.hのコメントと関数定義から明らか（サンプルコードは提供なし）

4. **なぜ違うライブラリ名（ym2151.dll）にしていたのか？**
   → 公式が名前を指定していないため独自に命名していた

5. **なぜ違う関数シグネチャ（Rust）にする必要があったのか？**
   → 必要なかった。誤り。すでに修正済み

6. **公式と同じにできない理由は？**
   → できる。実際にできていた。ライブラリ名とドキュメントを修正

### 今後

- ✅ すべてのライブラリは公式Nuked-OPM APIを提供
- ✅ ライブラリ名は `nukedopm` で統一（Pythonは後方互換性あり）
- ✅ ドキュメントで公式APIを提供していることを明記
- ✅ ユーザーは公式opm.hを参照できる

---

## 参考リンク

- 公式Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- 当リポジトリの分析ドキュメント: [OFFICIAL_API_ANALYSIS.md](OFFICIAL_API_ANALYSIS.md)
- 移行ガイド: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
- ym2151-emulator-examples: https://github.com/cat2151/ym2151-emulator-examples
