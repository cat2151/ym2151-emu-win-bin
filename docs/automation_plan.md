# GitHub Actions 自動化計画書

## 目的

手動エラー対処の手間を削減し、ビルドの信頼性を向上させるための自動化を実現する。

## 現状の課題

1. **ビルドエラーの検出が遅い**
   - daily buildで初めてエラーを検出
   - mainブランチに問題のあるコードがマージされる可能性

2. **1つの失敗で全体が失敗**
   - 4つのライブラリのうち1つでも失敗すると、成功したライブラリもコミットされない
   - 部分的な成功を活用できない

3. **問題の切り分けが困難**
   - 単一のワークフローで4つのライブラリをビルド
   - どのライブラリの問題かログから追跡が必要

4. **手動対応が必要**
   - エラー発生時の通知が不十分
   - 修正→テスト→コミットのサイクルが手動

## 自動化の目標

### 優先度1: 即時実施（本PRで実装）

#### 1-1. コードエラーの修正
**目的**: 現在のビルドエラーを解消

**実装内容**:
- Rust: `c_void` の未使用インポートを削除
- TypeScript: `opm_chip` → `opm_t` へ型名修正

**期待効果**:
- ビルド成功率: 50% → 100%

#### 1-2. ワークフローの分割
**目的**: 各ライブラリを独立してビルド

**実装内容**:
新しいワークフローファイルを作成:
- `.github/workflows/build-rust.yml`
- `.github/workflows/build-go.yml`
- `.github/workflows/build-python.yml`
- `.github/workflows/build-typescript.yml`

各ワークフローの特徴:
```yaml
name: Build [Library Name]

on:
  schedule:
    - cron: '0 0 * * *'  # 毎日UTC 00:00
  workflow_dispatch:       # 手動実行可能
  push:
    paths:                 # 該当ファイル変更時のみ実行
      - 'src/[library]/**'
      - 'scripts/build_[library].sh'

jobs:
  build:
    runs-on: [ubuntu-latest or windows-latest]
    steps:
      - checkout
      - setup environment
      - build
      - upload artifact
      - commit binary (on success)
```

**期待効果**:
- 1つの失敗が他に影響しない
- 成功したライブラリは自動コミット
- デバッグが容易に
- 必要なワークフローのみ再実行可能

#### 1-3. 成功時の自動コミット
**目的**: 成功したビルドを自動的にリポジトリに反映

**実装内容**:
各ワークフローで個別にコミット:
```yaml
- name: Commit binaries
  if: success()
  run: |
    git config --local user.email "github-actions[bot]@users.noreply.github.com"
    git config --local user.name "github-actions[bot]"
    git add binaries/[library]/
    git diff --staged --quiet || git commit -m "🤖 Update [Library] binary $(date +'%Y-%m-%d')"
    git push
```

**期待効果**:
- ビルド成功後、即座にバイナリが更新される
- 部分的な成功でもリリース可能

### 優先度2: 短期実施（1-2週間以内）

#### 2-1. プルリクエスト時のビルドチェック
**目的**: mainブランチへのマージ前にエラーを検出

**実装内容**:
`.github/workflows/pr-check.yml`:
```yaml
name: PR Build Check

on:
  pull_request:
    branches: [ main ]
    paths:
      - 'src/**'
      - 'scripts/**'

jobs:
  check-rust:
    runs-on: ubuntu-latest
    steps:
      - checkout
      - build rust
      - report status

  check-go:
    # 同様

  check-python:
    # 同様

  check-typescript:
    runs-on: windows-latest
    # 同様
```

**期待効果**:
- PRマージ前にビルドエラーを検出
- mainブランチの品質向上
- レビュー時に自動ビルド結果を確認可能

#### 2-2. ビルドエラー時の通知改善
**目的**: エラー発生を即座に把握

**実装内容**:
GitHub Actionsの通知機能を活用:
- メール通知（デフォルト）
- Slack/Discord Webhook（オプション）
- 自動Issue作成（オプション）

**実装例** (自動Issue作成):
```yaml
- name: Create Issue on Failure
  if: failure()
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: '[Library] Build Failed - ' + new Date().toISOString(),
        body: 'Build failed. See workflow run: ' + context.serverUrl + '/' + context.repo.owner + '/' + context.repo.repo + '/actions/runs/' + context.runId,
        labels: ['build-failure', 'automated']
      })
```

**期待効果**:
- エラーの見逃しを防止
- 問題の追跡が容易に

#### 2-3. ビルド前のリントチェック
**目的**: コンパイルエラーの事前検出

**実装内容**:
各ライブラリでリントツールを実行:

**Rust**:
```yaml
- name: Lint
  run: |
    cd src/rust
    cargo clippy --target x86_64-pc-windows-gnu -- -D warnings
```

**TypeScript/C++**:
```yaml
- name: Lint C++
  run: |
    cd src/typescript_node/src
    clang-format --dry-run --Werror *.cc
```

**Go**:
```yaml
- name: Lint
  run: |
    cd src/go
    go vet ./...
    golint ./...
```

**期待効果**:
- コンパイル前に問題を検出
- コードスタイルの統一
- ビルド時間の短縮（早期エラー検出）

### 優先度3: 中長期実施（1-3ヶ月以内）

#### 3-1. ビルド成果物の自動テスト
**目的**: ビルドされたライブラリが正常に動作することを確認

**実装内容**:
各言語でテストコードを作成:

**Rust**:
```rust
// tests/integration_test.rs
#[test]
fn test_library_loads() {
    // ライブラリが正常にロード可能か確認
}
```

**TypeScript**:
```javascript
// test/basic.test.js
const ym2151 = require('../build/Release/ym2151.node');

test('module loads', () => {
  expect(ym2151).toBeDefined();
});

test('can create instance', () => {
  const chip = new ym2151.YM2151();
  expect(chip).toBeDefined();
});
```

**期待効果**:
- ビルドの成功だけでなく、動作も確認
- リグレッションの検出
- 品質の向上

#### 3-2. 依存関係の自動更新
**目的**: セキュリティ更新と新機能対応

**実装内容**:
Dependabot設定 (`.github/dependabot.yml`):
```yaml
version: 2
updates:
  - package-ecosystem: "cargo"
    directory: "/src/rust"
    schedule:
      interval: "weekly"
  
  - package-ecosystem: "npm"
    directory: "/src/typescript_node"
    schedule:
      interval: "weekly"
  
  - package-ecosystem: "gomod"
    directory: "/src/go"
    schedule:
      interval: "weekly"
```

**期待効果**:
- セキュリティ脆弱性の自動修正
- 依存関係の最新化
- 手動更新作業の削減

#### 3-3. ビルドキャッシュの最適化
**目的**: ビルド時間の短縮

**実装内容**:
各ワークフローでキャッシュを活用:

**Rust**:
```yaml
- uses: Swatinem/rust-cache@v2
  with:
    key: ${{ runner.os }}-rust-${{ hashFiles('**/Cargo.lock') }}
```

**Node.js**:
```yaml
- uses: actions/setup-node@v4
  with:
    cache: 'npm'
    cache-dependency-path: src/typescript_node/package-lock.json
```

**期待効果**:
- ビルド時間: 6-7分 → 3-4分
- GitHub Actions使用時間の削減
- 開発サイクルの高速化

## 実装タイムライン

### Week 1（本PR）
- ✅ コードエラー修正
- ✅ ワークフロー分割
- ✅ 成功時の自動コミット
- ✅ ドキュメント作成（本文書含む）

### Week 2-3
- ⏳ PRチェックワークフロー追加
- ⏳ ビルドエラー通知改善
- ⏳ リントチェック追加

### Week 4-8
- ⏳ テストコード作成
- ⏳ ビルドキャッシュ最適化

### Month 3
- ⏳ Dependabot設定
- ⏳ 全体の最適化とドキュメント更新

## 成功指標（KPI）

### ビルド成功率
- 現在: 50% (2/4)
- 目標: 95%以上

### エラー検出時間
- 現在: Daily buildまで（最大24時間）
- 目標: PRマージ前（即時）

### 問題解決時間
- 現在: 30-120分（手動対応）
- 目標: 10-30分（自動化により短縮）

### ビルド時間
- 現在: 約6-7分
- 目標: 3-4分（キャッシュ最適化後）

## リスクと対策

### リスク1: ワークフロー分割による管理複雑化
**対策**:
- 共通部分はComposite Actionとして抽出
- ドキュメント整備
- 命名規則の統一

### リスク2: 自動コミットによる不要な変更
**対策**:
- `git diff --staged --quiet` で変更がある場合のみコミット
- コミットメッセージに日付を含める
- ビルド結果の検証ステップ追加

### リスク3: 通知過多
**対策**:
- 重要度に応じた通知設定
- 同一エラーの重複通知を防ぐ
- 週次サマリーレポート

## まとめ

この自動化計画により、以下を実現します：

1. **即座のエラー検出**: PRマージ前にビルドエラーを検出
2. **部分的な成功の活用**: 成功したライブラリは自動コミット
3. **問題の早期発見**: リント・テストによる事前チェック
4. **運用負荷の軽減**: 自動化による手動作業の削減
5. **品質の向上**: 継続的な検証とテスト

これらにより、開発効率と製品品質が大幅に向上することが期待されます。
