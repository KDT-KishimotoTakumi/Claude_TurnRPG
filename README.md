# ClaudeCode_Tools

ゲーム開発（Unity / Unreal Engine / DXライブラリ）向けの Claude Code 設定集です。

## 構成

```
ClaudeCode_Tools/
├── README.md
├── common/
│   └── CLAUDE.md              # 全プロジェクト共通のルール
├── agents/                    # サブエージェント定義
│   ├── game-explorer.md       # コードベース調査
│   ├── unity-specialist.md    # Unity (C#)
│   ├── unreal-specialist.md   # Unreal Engine (C++ / Blueprint)
│   ├── dxlib-specialist.md    # DXライブラリ (C++)
│   └── code-reviewer.md       # コードレビュー
├── skills/                    # スキル（作業手順）
│   ├── unity-workflow/SKILL.md
│   ├── unreal-workflow/SKILL.md
│   ├── dxlib-workflow/SKILL.md
│   └── speckit-setup/         # Spec Kit 導入（SKILL.md / hermes.md）
└── templates/
    └── .claude/
        └── settings.json      # プロジェクト用設定テンプレート
```

## 使い方

### 全プロジェクトで使う場合（ユーザー設定）

```powershell
Copy-Item common\CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"
Copy-Item agents\*.md "$env:USERPROFILE\.claude\agents\"
Copy-Item skills\* "$env:USERPROFILE\.claude\skills\" -Recurse
```

### 特定のプロジェクトだけで使う場合

```powershell
$proj = "C:\path\to\your\project"
Copy-Item templates\.claude "$proj\" -Recurse
Copy-Item agents\*.md "$proj\.claude\agents\"
Copy-Item skills\* "$proj\.claude\skills\" -Recurse
```

コピーしたら、使わないエンジンのエージェントとスキルは消してかまいません。

## 公式ドキュメントの反映内容

[サブエージェント](https://code.claude.com/docs/en/sub-agents) / [ベストプラクティス](https://code.claude.com/docs/en/best-practices) / [スキル](https://code.claude.com/docs/en/skills) を基に、次の方針を取り入れています。

| 出典 | 反映先 | 内容 |
| - | - | - |
| サブエージェント | `agents/*.md` | `description` で委譲の条件を明示（レビュー担当は "積極的に使う"）。読み取り専用は `tools` を最小化。調査は `model: haiku`、実装・レビューは `sonnet`。専門エージェントは `skills` で対応するワークフローを事前読み込み |
| ベストプラクティス | `common/CLAUDE.md` | 調査 → 計画 → 実装 → コミット、実行できる確認手段での検証、根本原因の修正、コンパクト時に残す情報、サブエージェントへルールを明示して渡すこと。CLAUDE.md は短く保つ |
| ベストプラクティス | `code-reviewer.md` | 新しい文脈での敵対的レビュー。正しさに関わる指摘だけに絞り、過剰設計を避ける |
| スキル | `skills/*/SKILL.md` | `when_to_use` と `argument-hint` を追加し、`$ARGUMENTS` で依頼内容を受け取る |

メモ: `skills` で事前読み込みされた場合、`$ARGUMENTS` は空になります。スキルを `/unity-workflow ...` のように直接呼ぶときに使われます。

## エージェントの自動切り替え

次の3つが連携して、指示しなくても作業内容に合ったエージェントが呼ばれます。

1. **`description`**: 各エージェントに「どんな依頼で積極的に委譲するか」を書いてあります。Claude はこれを見て委譲先を決めます。
2. **`common/CLAUDE.md`**: 「エージェントの自動選択」の表で、作業内容とエージェントの対応を明示しています。
3. **`templates/.claude/hooks/detect-engine.ps1`**: セッション開始時にエンジン（Unity / Unreal / DXライブラリ）を判別し、使うエージェントを Claude に伝えます。`templates/.claude/settings.json` の `SessionStart` フックから実行されます。

フックはプロジェクト単位の設定です。「特定のプロジェクトだけで使う場合」の手順で `templates\.claude` をコピーしてください（`hooks` フォルダも一緒にコピーされます）。

## Spec Kit の導入

[GitHub Spec Kit](https://github.com/github/spec-kit) を導入するスキル `speckit-setup` を用意しています。副作用があるため、手動呼び出し専用です。

```
/speckit-setup            # Claude Code 用（既定）
/speckit-setup hermes     # Hermes Agent 用
```

導入したいプロジェクトのルートで実行します。Specify CLI の確認、`specify init --here --integration <統合>`、検証までを行います。導入後は `/speckit-constitution` → `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` の順に使います。
