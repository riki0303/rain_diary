# CLAUDE.md

## 開発ワークフロー

機能追加・変更の依頼を受けた場合、**必ずエージェントチームを作成**して `developer` → `reviewer` の2人体制で進める。各エージェントの詳細は `.claude/agents/` を参照。

### リーダーの役割
- `developer` と `reviewer` のチームを作成し、developer にタスクを割り当てる
- developer 完了後に reviewer を動かす
- reviewer の報告を受けて、必要なら developer に修正を依頼する
- 最終的な結果をユーザーに報告する
- 不明点があった場合、必ずユーザーに質問する（勝手に進めない）

### ブランチ運用
- **mainブランチへの直接pushは禁止**
- 作業は必ず feature ブランチ（例: `feature/<issue番号>-<説明>`）で行う

## アーキテクチャ

### 主要な規約
- **認可**: `app/policies/` に Pundit ポリシーを配置。全コントローラーで `authorize` と `policy_scope` を呼ぶ。`Pundit::NotAuthorizedError` は `ApplicationController` でレスキューする
- **ビュー**: Haml テンプレート (`.html.haml`)。フォームは Simple Form + Bootstrap を使用
- **フロントエンド**: Hotwire (Turbo + Stimulus)、Bootstrap 5、esbuild + Sass
