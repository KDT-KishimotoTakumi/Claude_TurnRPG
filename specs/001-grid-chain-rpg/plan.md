# Implementation Plan: 盤面配置×技連鎖進化ターン制RPG（最小縦切り）

**Branch**: `001-grid-chain-rpg` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-grid-chain-rpg/spec.md`

## Summary

5x5 盤面の配置型戦闘、技の連鎖による派生技への進化、戦闘間の準備フェーズ、5 戦のランを、Unity 6 で作る。
ゲームのルールはすべて Unity 非依存の純 C# アセンブリ（`TurnRpg.Core`）に置き、MonoBehaviour は入出力に徹する
（Humble Object）。ルールは EditMode テストでカバレッジ 90% 以上を保証し、画面・入力・セーブ・遷移は PlayMode の E2E で
全受け入れシナリオを自動検証する。乱数は自前のシード付き PRNG に統一し、敵 AI も乱数を使わない決定論にする。
技・敵・アイテム・装備の数値は JSON データとして外出しし、再コンパイルなしで調整できるようにする。

## Technical Context

**Language/Version**: C# 9（Unity 6000.0.42f1 / .NET Standard 2.1）

**Primary Dependencies**: Input System 1.11.2、uGUI 2.0.0、Test Framework 1.4.5、Code Coverage（`com.unity.testtools.codecoverage` 1.2.x。導入時に解決して固定）、Newtonsoft Json（`com.unity.nuget.newtonsoft-json`。導入時に解決して固定）

**Storage**: ローカルファイル 1 つ（中断セーブ、JSON、版数つき、一時ファイル経由の置換で保存）

**Testing**: Unity Test Framework の EditMode（Core のユニットテスト）と PlayMode（E2E、Input System の `InputTestFixture` で仮想デバイスを操作）。カバレッジは Code Coverage の CLI で計測

**Target Platform**: Windows PC（Standalone）。マウス・キーボード・ゲームパッド

**Project Type**: ゲーム（Unity デスクトップアプリ）

**Performance Goals**: 60 fps を維持。敵 1 体の行動判断は 50 ms 以内（盤面評価の探索量に上限を設ける）。毎フレーム処理でのメモリ確保なし

**Constraints**: ロジック層のラインカバレッジ 90% 以上。全受け入れシナリオに E2E を対応付け。同じシードと入力列で結果が完全一致（SC-004）。ユーザー向け文言は日本語

**Scale/Scope**: 画面 4 種（タイトル・準備・戦闘・結果）、職 4、基本技 12・派生技 12、通常の敵 3 種＋ボス 1、消耗品 2 種、装備 4 種

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原則 | 判定 | 計画での担保 |
|------|------|--------------|
| I. TDD | 合格 | タスクは「テスト → 実装」の順で並べ、各タスク組に Red 確認を含める。コミットはテスト追加が実装より先 |
| II. カバレッジ 90% | 合格 | 計測対象は `TurnRpg.Core` のみ。`tools/check-coverage.ps1` が 90% 未満で失敗する。除外は `docs/coverage-exclusions.md` |
| III. E2E の網羅 | 合格 | 受け入れシナリオ ID を E2E テストの属性に記し、EditMode の整合性テストが「E2E のないシナリオ」を失敗にする |
| IV. Humble Object | 合格 | `TurnRpg.Core` は `noEngineReferences`。View は `TurnRpg.Game` |
| V. 決定論 | 合格 | 自前 PRNG（PCG32）をシード注入。`UnityEngine.Random` と `DateTime.Now` は Core で禁止（テストで検査） |
| VI. 入力の抽象化 | 合格 | Input Action アセットに操作を集約。3 デバイスの E2E を用意 |
| VII. 仕様駆動 | 合格 | 本計画は clarify 済みの仕様に基づく |
| VIII. 変更の規律 | 合格 | `.meta` や `Library/` は手編集しない |
| IX. パフォーマンス | 合格 | 毎フレーム処理でのメモリ確保を避け、View は状態変化時のみ更新 |
| X. 素材 | 合格 | ドット絵は ASCII の画素図から生成する自作。出典は `docs/assets-licenses.md` に記録 |

Phase 1 設計後の再評価: **合格**（違反なし。下の複雑性の記録は例外ではなく構成の説明）。

## Project Structure

### Documentation (this feature)

```text
specs/001-grid-chain-rpg/
├── plan.md              # 本ファイル
├── research.md          # Phase 0: 技術判断と未決事項の決定
├── data-model.md        # Phase 1: エンティティ・状態遷移・初期データ
├── quickstart.md        # Phase 1: 検証手順（テスト・カバレッジ・E2E）
├── contracts/
│   ├── core-api.md          # Core が View に公開する操作とイベント
│   ├── input-actions.md     # 入力アクションの定義
│   └── save-format.md       # 中断セーブの JSON スキーマ
└── tasks.md             # /speckit-tasks の出力（本コマンドでは作らない）
```

### Source Code (repository root)

Unity プロジェクトはリポジトリ直下の `game/` に置く。

```text
game/
├── Assets/
│   ├── Scripts/
│   │   ├── Core/                       # asmdef: TurnRpg.Core（noEngineReferences）
│   │   │   ├── Random/                 # PCG32、シード
│   │   │   ├── Board/                  # マス、座標、向き、範囲計算
│   │   │   ├── Units/                  # ユニット、能力値、職
│   │   │   ├── Skills/                 # 技、派生、効果の解決
│   │   │   ├── Chain/                  # 連鎖の判定と進化
│   │   │   ├── Battle/                 # フェーズ制、行動、勝敗
│   │   │   ├── EnemyAi/                # 盤面評価と行動選択
│   │   │   ├── Run/                    # ラン生成、準備フェーズ、体力の引き継ぎ
│   │   │   ├── Items/                  # 消耗品、装備
│   │   │   ├── Save/                   # 状態の直列化、版数、破損検知
│   │   │   ├── Text/                   # 日本語の文言表（TextTable）
│   │   │   ├── Input/                  # 入力モードの管理（InputModeTracker）
│   │   │   └── Data/                   # データ定義、検証
│   │   ├── Game/                       # asmdef: TurnRpg.Game（View、入力、セーブ I/O、シーン）
│   │   │   ├── Input/
│   │   │   ├── Views/
│   │   │   ├── Screens/
│   │   │   └── Infrastructure/         # ファイル I/O、データ読み込み
│   │   └── Editor/                     # asmdef: TurnRpg.Editor（画素図からスプライト生成、シーン生成 SceneBuilder）
│   ├── StreamingAssets/GameData/       # skills.json / enemies.json / items.json など
│   ├── Art/Sprites/                    # 自作のドット絵
│   ├── Scenes/
│   ├── Settings/                       # Input Action アセット
│   └── Tests/                          # Unity は Assets/ 配下のみコンパイルする
│       ├── EditMode/                   # asmdef: TurnRpg.Tests.EditMode（Core のテスト）
│       └── PlayMode/                   # asmdef: TurnRpg.Tests.PlayMode（E2E）
├── Packages/
└── ProjectSettings/

tools/
├── run-tests.ps1                       # EditMode/PlayMode をバッチモードで実行
└── check-coverage.ps1                  # Core のラインカバレッジを検証（90% 未満で失敗）

docs/
├── coverage-exclusions.md
├── assets-licenses.md
└── e2e-traceability.md                 # 受け入れシナリオと E2E の対応表
```

**Structure Decision**: ルール（Core）と表示・入力・I/O（Game）をアセンブリで分離し、Core だけをカバレッジの計測対象にする。
Core は `UnityEngine` を参照できないため、乱数・時刻・ファイル・データ読み込みは Core の抽象（インターフェース）越しに Game が実装する。

## Complexity Tracking

> 憲法チェックに違反はないため、例外の記録はない。参考として、複数アセンブリ構成の理由を記す。

| 構成 | 必要な理由 | より単純な案を採らない理由 |
|------|-----------|----------------------------|
| asmdef を 5 つ（Core / Game / Editor / EditMode テスト / PlayMode テスト） | Core をエンジン非依存にし、カバレッジ計測の対象を明確にするため | 1 アセンブリではロジックと View の混在を防げず、原則 II・IV を満たせない |
| ルールのデータを JSON に外出し | 数値調整を再コンパイルなしで行い、データ検証を Core のテストにするため | コードに直書きするとバランス調整のたびに実装変更が必要になる |
