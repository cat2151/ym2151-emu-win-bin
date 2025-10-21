# PR Summary: ライブラリの呼び出しや名称についてwrappingをやめ、公式が提唱しているものに修正する

## 概要

このPRは、当リポジトリが提供するライブラリが**公式Nuked-OPM APIをそのまま提供している**ことを明確化し、ライブラリ名とドキュメントを修正したものです。

## 変更の背景

Issue提起された問題:
1. ライブラリ名が `ym2151.dll` / `libym2151.a` で、どのエミュレータか不明瞭
2. 「wrapper」という表現で、カスタムAPIと誤解される可能性
3. Rustの `lib.rs` で公式と異なる関数シグネチャを宣言していた

**実態**: すでに公式Nuked-OPM APIを提供していたが、名前とドキュメントが不明瞭だった。

## 主な変更内容

### 1. ライブラリ名の変更

| 言語 | 変更前 | 変更後 |
|------|--------|--------|
| Rust | `libym2151.a` | `libnukedopm.a` |
| Rust | `ym2151.dll` | `nukedopm.dll` |
| Go | `libym2151.a` | `libnukedopm.a` |
| Python | `ym2151.dll` | `nukedopm.dll` |

### 2. コード修正

#### Rust (`src/rust/`)
- **lib.rs**: 誤った関数シグネチャ宣言を削除、公式API使用を明記するドキュメントに変更
- **Cargo.toml**: パッケージ名を `ym2151` → `nukedopm` に変更
- **README.md**: 公式APIの使い方を詳細に記載

#### Go (`src/go/`)
- **Makefile**: ターゲット名を `libym2151.a` → `libnukedopm.a` に変更
- **README.md**: 公式APIの使い方を詳細に記載

#### Python (`src/python/`)
- **Makefile**: 
  - 主ターゲット: `nukedopm.dll`
  - レガシー: `ym2151.dll` (コピー)
- **README.md**: 公式APIの使い方を詳細に記載

### 3. ビルドスクリプト更新

すべてのビルドスクリプトを新しいライブラリ名に対応:
- `scripts/build_rust.sh`
- `scripts/build_go.sh`
- `scripts/build_python.sh`

### 4. GitHub Actions更新

CI/CDパイプラインを新しいライブラリ名に対応:
- `.github/workflows/build-rust.yml`
- `.github/workflows/build-go.yml`
- `.github/workflows/build-python.yml`

### 5. ドキュメント整備

#### 新規作成（合計 922 行）

1. **OFFICIAL_API_ANALYSIS.md** (291行)
   - 公式Nuked-OPM APIとの詳細比較
   - 現在の実装の問題点と解決策
   - 推奨される対応方針

2. **MIGRATION_GUIDE.md** (157行)
   - ユーザー向け移行ガイド
   - 言語別の変更方法
   - よくある質問

3. **ISSUE_RESOLUTION_SUMMARY.md** (220行)
   - Issue質問への完全な回答
   - なぜ違う名前だったのか
   - なぜ公式と同じにできるのか

4. **LIBRARY_STRUCTURE.md** (254行)
   - ビジュアル図解
   - 修正前後の構造比較
   - ビルドフローの説明

#### 既存ドキュメント更新

- **README.md**: 公式API提供を明記
- **docs/libraries.md**: 公式API情報を追加
- **docs/LIBRARY_REQUIREMENT_CHECK.md**: 新しいライブラリ名に更新
- すべての言語別README: 公式APIの使い方を詳細化

## 影響範囲

### Breaking Changes

- **Rust**: ライブラリ名が変更（`libym2151.a` → `libnukedopm.a`）
- **Go**: ライブラリ名が変更（`libym2151.a` → `libnukedopm.a`）
- **Python**: ライブラリ名が変更（`ym2151.dll` → `nukedopm.dll`）
- **影響**: ライブラリファイル名の参照を変更する必要があります

### API Changes

**APIは変更ありません**
- すべての関数は公式Nuked-OPM APIそのまま
- 関数名、シグネチャは opm.h と完全一致
- ユーザーコードの変更は不要（ライブラリ名のみ）

## ファイル変更統計

```
20 files changed, 1228 insertions(+), 119 deletions(-)
```

### 内訳

- **ソースコード**: 20ファイル
- **新規ドキュメント**: 4ファイル（922行）
- **ビルドスクリプト**: 3ファイル
- **GitHub Actions**: 3ファイル

## テスト

### 必要なテスト

- [ ] Rustビルドが成功すること（新しいライブラリ名で）
- [ ] Goビルドが成功すること（新しいライブラリ名で）
- [ ] Pythonビルドが成功すること（両方のファイル名で）
- [ ] ym2151-emulator-examplesから使用できること（特にPython）

**注意**: mingw-w64が利用可能な環境でのみビルド可能

## リリースノート

### v0.2.0 (予定)

#### 変更点

**ライブラリ名変更**:
- Rust: `libnukedopm.a`, `nukedopm.dll`
- Go: `libnukedopm.a`
- Python: `nukedopm.dll`

**明確化**:
- すべてのライブラリは公式Nuked-OPM APIを提供
- カスタムラッパーは存在しない
- ユーザーは公式opm.hを参照可能

**ドキュメント追加**:
- 公式APIの詳細分析
- 移行ガイド
- ビジュアル構造図解

#### 移行方法

**Rust/Go**: リンカー設定を変更
```bash
# 旧: -lym2151
# 新: -lnukedopm
```

**Python**: ライブラリファイル名を変更
```python
# 旧: lib = ctypes.CDLL('./ym2151.dll')
# 新: lib = ctypes.CDLL('./nukedopm.dll')
```

**API**: 変更なし（公式Nuked-OPM APIそのまま）

## 参考リンク

- 公式Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- 公式API (opm.h): https://github.com/nukeykt/Nuked-OPM/blob/master/opm.h
- ym2151-emulator-examples: https://github.com/cat2151/ym2151-emulator-examples

## ドキュメントインデックス

1. [OFFICIAL_API_ANALYSIS.md](docs/OFFICIAL_API_ANALYSIS.md) - 技術的な詳細分析
2. [MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) - ユーザー向け移行ガイド
3. [ISSUE_RESOLUTION_SUMMARY.md](docs/ISSUE_RESOLUTION_SUMMARY.md) - Issue回答
4. [LIBRARY_STRUCTURE.md](docs/LIBRARY_STRUCTURE.md) - ビジュアル図解

## 結論

✅ ライブラリ名を公式Nuked-OPMを示すものに変更
✅ 公式APIをそのまま提供していることを明確化
✅ 不要なwrapper宣言を削除
✅ 充実したドキュメント（922行追加）
✅ すべてのIssue質問に回答

このPRにより、ユーザーは：
- ライブラリがNuked-OPMであることを理解できる
- 公式opm.hを参照して使用できる
- カスタムラッパーではないことを理解できる
