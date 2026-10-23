---
name: speckit-setup
description: GitHub Spec Kit をカレントプロジェクトに導入する手順。/speckit-setup で呼び出すと、Specify CLI のインストールから speckit-* スキルの配置、検証までを行う。
disable-model-invocation: true
argument-hint: "[claude | hermes]"
---

# Spec Kit 導入手順

導入先は**カレントディレクトリ（プロジェクトのルート）**です。引数でエージェント統合を選びます（省略時は `claude`）。

統合: $ARGUMENTS

- `claude`: Claude Code 用。スキルは `.claude/skills/speckit-*` に作られ、プロジェクト内で完結します。
- `hermes`: Hermes Agent 用。手順は `hermes.md` を参照します。

パスは絶対パスを決め打ちせず、環境から解決します。手順を勝手に別の方法へ切り替えません。

## 手順1: Specify CLI のインストール

```powershell
specify --version
```

バージョンが返ればインストール済みなので手順2へ進みます。失敗する場合のみ次を実行します。

```powershell
uv --version            # なければ pip install uv
uv tool install --from git+https://github.com/github/spec-kit.git specify-cli
specify --version
```

## 手順2: プロジェクトへの導入

導入先がプロジェクトのルートであることを確認してから実行します。既存ファイルがある場合、`--force` は上書きされる可能性があるため、先に `git status` で未コミットの変更がないか確認し、あればユーザーに伝えます。

```powershell
specify init --here --integration claude --force --non-interactive
```

- `--no-git` というオプションは存在しないので使いません。
- `.specify/`（テンプレート・スクリプト）が作られます。自前で SKILL.md を書く必要はありません。

## 手順3: 検証

すべて確認してから完了を報告します。

1. `.specify/integration.json` があり、`installed_integrations` に選んだ統合（`claude`）が含まれる。
2. `.claude/skills/speckit-*/SKILL.md` に、`{SCRIPT}` / `{ARGS}` / `__SPECKIT_COMMAND_*__` / `__AGENT__` などの未処理プレースホルダーが残っていない。
3. Windows では `.specify/scripts/powershell/*.ps1`、Linux/macOS では `.specify/scripts/bash/*.sh` がスキル本文に埋め込まれている。
4. 前提スクリプトが起動する。「Feature directory not found」系のエラーは、まだ機能を作っていないため正常。
   - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .specify/scripts/powershell/check-prerequisites.ps1 -Json`
   - Linux/macOS: `bash .specify/scripts/bash/check-prerequisites.sh --json`

## 完了後

- コマンドの流れ: `/speckit-constitution` → `/speckit-specify` → (`/speckit-clarify`) → `/speckit-plan` → (`/speckit-checklist`) → `/speckit-tasks` → (`/speckit-analyze`) → `/speckit-implement`
- 新しいスキルは次回セッションから有効です（作成直後は再起動が必要な場合があります）。
- `.specify/` がない状態で speckit-* スキルを実行しません。
