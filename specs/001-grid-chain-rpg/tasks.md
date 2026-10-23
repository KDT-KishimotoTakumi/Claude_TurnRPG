---

description: "盤面配置×技連鎖進化ターン制RPG（最小縦切り）のタスク一覧"
---

# Tasks: 盤面配置×技連鎖進化ターン制RPG（最小縦切り）

**Input**: `/specs/001-grid-chain-rpg/` の plan.md、spec.md、research.md、data-model.md、contracts/、quickstart.md

**Prerequisites**: plan.md、spec.md（ともに作成済み）

**Tests**: 憲法の原則 I（TDD）・II（カバレッジ 90%）・III（E2E）により、**テストは必須**。各ユーザーストーリーは「テストを書く → 失敗を確認する → 実装する」の順で進める。

**Organization**: タスクはユーザーストーリーごとにまとめる。各ストーリーは単独でテスト可能な増分とする。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行できる（別ファイルで、未完了のタスクへの依存がない）
- **[Story]**: 対応するユーザーストーリー（US1〜US6）
- 説明にファイルパスを含める

## Path Conventions

- Unity プロジェクト: `game/`。以下 `game/` を省略せず、リポジトリ直下からのパスで書く
- Core: `game/Assets/Scripts/Core/`（asmdef `TurnRpg.Core`）
- Game: `game/Assets/Scripts/Game/`（asmdef `TurnRpg.Game`）
- EditMode テスト: `game/Assets/Tests/EditMode/`、PlayMode（E2E）: `game/Assets/Tests/PlayMode/`
- ツール: `tools/`、ドキュメント: `docs/`

## TDD の運用ルール（全フェーズ共通）

1. 「テスト」タスクを先にコミットし、**失敗（Red）を確認した出力**をコミットメッセージまたは作業記録に残す。
2. 実装タスクでテストを通す（Green）。次にリファクタリングし、テストが通ることを再確認する。
3. 1 つのタスクが終わるたびに `pwsh tools/run-tests.ps1 -Platform EditMode` を実行する。PlayMode は各ストーリーの終了時に実行する。
4. ロジックを `TurnRpg.Core` の外に置いて数値を稼ぐことを禁止する（憲法 II）。

---

## Phase 1: Setup（プロジェクトの土台）

**Purpose**: Unity プロジェクト、テスト基盤、品質ゲートのツールを整える

- [ ] T001 Unity 6000.0.42f1 のバッチモードで `game/` に空の Unity プロジェクトを作成する（`"C:\Program Files\Unity\Hub\Editor\6000.0.42f1\Editor\Unity.exe" -batchmode -quit -createProject game`）。日本語パスで失敗する場合は、ASCII パスへのジャンクションを作って回避し、その手順を `docs/dev-environment.md` に記録する（research.md R-11）
- [ ] T002 [P] `.gitignore` に Unity の生成物（`game/Library/`、`game/Temp/`、`game/Logs/`、`game/UserSettings/`、`game/obj/`、`*.csproj`、`*.sln`、カバレッジ結果 `game/CodeCoverage/`、`TestResults/`）を追記する（既存の内容は変えない）
- [ ] T003 `game/Packages/manifest.json` に Input System 1.11.2、uGUI 2.0.0、Test Framework 1.4.5、Code Coverage（`com.unity.testtools.codecoverage` 1.2.x）、Newtonsoft Json（`com.unity.nuget.newtonsoft-json`）を固定し、`game/ProjectSettings/ProjectSettings.asset` の Active Input Handling を「Input System Package (New)」にする。解決した版を `docs/dev-environment.md` に記録する
- [ ] T004 asmdef を作成する: `game/Assets/Scripts/Core/TurnRpg.Core.asmdef`（`noEngineReferences: true`、Newtonsoft Json のみ参照）、`game/Assets/Scripts/Game/TurnRpg.Game.asmdef`（Core・Input System・uGUI を参照）、`game/Assets/Scripts/Editor/TurnRpg.Editor.asmdef`（Editor のみ）、`game/Assets/Tests/EditMode/TurnRpg.Tests.EditMode.asmdef`、`game/Assets/Tests/PlayMode/TurnRpg.Tests.PlayMode.asmdef`（それぞれ Test Framework を参照し、`TurnRpg.Core` と `TurnRpg.Game` を参照。EditMode 側は `TurnRpg.Editor` も参照する）
- [ ] T005 [P] `tools/tests/check-coverage.tests.ps1` と `tools/tests/fixtures/summary-89.xml`、`summary-90.xml`、`summary-missing.xml` を書く。期待: 89% は終了コード 1、90% は 0、結果ファイルなしは 2（先にテストを書き、Red を確認する）
- [ ] T006 `tools/check-coverage.ps1` を実装する。Code Coverage の `Summary.xml` から `TurnRpg.Core` のラインカバレッジを読み、90% 未満なら非ゼロで終了する。T005 のテストを通す
- [ ] T007 [P] `tools/run-tests.ps1` を実装する。引数 `-Platform EditMode|PlayMode`、`-Coverage`、`-Filter`。Unity をバッチモードで起動し、結果を `TestResults/` に出力し、失敗があれば非ゼロで終了する。カバレッジ有効時は `-enableCodeCoverage -coverageOptions "assemblyFilters:+TurnRpg.Core;generateAdditionalMetrics"` を付ける（research.md R-08）
- [ ] T008 [P] `docs/coverage-exclusions.md`、`docs/assets-licenses.md`、`docs/e2e-traceability.md` の雛形を作る（除外対象は View・MonoBehaviour・自動生成コード・Editor 拡張に限ると明記する）
- [ ] T009 煙テスト: `game/Assets/Tests/EditMode/SmokeTests.cs` に常に成功するテストを 1 つ置き、`pwsh tools/run-tests.ps1 -Platform EditMode -Coverage` と `pwsh tools/check-coverage.ps1` がバッチモードで動くことを確認する。結果を `docs/dev-environment.md` に記録し、確認後に煙テストを削除する

**Checkpoint**: テスト実行とカバレッジ計測がバッチモードで動く

---

## Phase 2: Foundational（全ストーリーの前提）

**Purpose**: 乱数、盤面の幾何、データ読み込み、入力、仕様との整合テストなど、どのストーリーも使う土台

**⚠️ CRITICAL**: このフェーズが終わるまでユーザーストーリーに着手しない

### テスト（先に書いて Red を確認する）

- [ ] T010 [P] `game/Assets/Tests/EditMode/Random/Pcg32Tests.cs`: 同じシードで同じ列が得られる、異なるシードで異なる列、`NextInt(max)` が `0 ≤ x < max`、用途別の派生（`Derive(label)`）が独立した列になる、既知のシード 42 の先頭 5 値が固定値と一致する
- [ ] T011 [P] `game/Assets/Tests/EditMode/Board/CellTests.cs` と `DirectionTests.cs`: `Cell` は `x`(0〜4), `y`(0〜4)、盤面外は `IsInside` が偽、`Direction` は Up/Down/Left/Right、回転（右 90°）、反対方向、隣接判定（上下左右）、同一マス判定
- [ ] T012 [P] `game/Assets/Tests/EditMode/Units/StatsTests.cs` と `UnitTests.cs`: `Stats` は `maxHp`, `attack`, `defense`, `speed`（整数）、装備補正の加算、`Unit` は `0 ≤ hp ≤ maxHp`、`cell` は盤面内、`hp == 0` で倒れる
- [ ] T013 [P] `game/Assets/Tests/EditMode/Data/DataValidatorTests.cs`: 味方の技が基本 12 と派生 12 の計 24 種（敵の技は別表で、参照切れと範囲の整合性のみ検証し、24 種に含めない）、派生先が存在し派生技は終端（`evolvesTo` が null）、職ごとに基本技 3、能力値が正の整数、敵が通常 3 種とボス 1、装備 4 種、消耗品 2 種。参照切れ・循環・重複 ID は検証失敗になる
- [ ] T014 [P] `game/Assets/Tests/EditMode/Meta/CoreIsolationTests.cs`: `TurnRpg.Core` のソースに `UnityEngine`、`UnityEngine.Random`、`System.Random`、`DateTime.Now`、`DateTime.UtcNow` が出現しない（憲法 IV・V）。asmdef の `noEngineReferences` が真である
- [ ] T015 [P] `game/Assets/Tests/EditMode/Meta/ScenarioTraceabilityTests.cs`: `spec.md` から受け入れシナリオ ID（`US{n}-AS{m}`。`### User Story N` と番号付きリストから導出。全 26 件）を抽出し、`TurnRpg.Tests.PlayMode` の `[Scenario("US1-AS1")]` 属性と突き合わせる。E2E のないシナリオがあれば失敗する。`docs/e2e-traceability.md` を生成する（SC-008）
- [ ] T016 [P] `game/Assets/Tests/EditMode/Input/InputActionsTests.cs`: `GameInput.inputactions` に `Navigate`, `Submit`, `Cancel`, `EndPhase`, `NextTab`, `PrevTab` があり、各アクションがキーボード・マウス・ゲームパッドのいずれにもバインドされている（contracts/input-actions.md）

### 実装

- [ ] T017 [P] `game/Assets/Scripts/Core/Random/Pcg32.cs` と `IRandom.cs` を実装し、T010 を通す
- [ ] T018 [P] `game/Assets/Scripts/Core/Board/Cell.cs`、`Direction.cs`、`Side.cs` を実装し、T011 を通す（自陣側は y=0〜1、敵陣側は y=3〜4、y=2 は中立）
- [ ] T019 [P] `game/Assets/Scripts/Core/Units/Stats.cs`、`Unit.cs`、`Job.cs` を実装し、T012 を通す
- [ ] T020 [P] `game/Assets/Scripts/Core/Data/`（`SkillDef.cs`、`EnemyType.cs`、`ItemDef.cs`、`EquipmentDef.cs`、`IDataSource.cs`、`GameData.cs`、`DataValidator.cs`）を実装し、T013 を通す。JSON の読み込みは Newtonsoft Json を使う
- [ ] T021 `game/Assets/StreamingAssets/GameData/skills.json`、`enemy-skills.json`、`enemies.json`、`items.json`、`equipment.json`、`jobs.json` を data-model.md の初期データ（対象マスの定義、敵の技を含む）から作り、T013 の検証を通す。JSON の置き場所はここだけとし、複製しない
- [ ] T022 [P] `game/Assets/Scripts/Game/Infrastructure/StreamingDataSource.cs` を実装する（`IDataSource` の Unity 実装。`game/Assets/StreamingAssets/GameData/` から読み込む）
- [ ] T023 `game/Assets/Settings/GameInput.inputactions` を contracts/input-actions.md どおり作り、T016 を通す
- [ ] T024 [P] `game/Assets/Scripts/Game/Input/InputRouter.cs`: Input Action を抽象操作（`Navigate`, `Submit` など）に変換して画面へ渡す MonoBehaviour。判断は持たせない
- [ ] T025 [P] `game/Assets/Scripts/Editor/PixelArtGenerator.cs`: ASCII の画素図（1 文字 = 1 ピクセル、パレット定義つき）から PNG を生成する。`game/Assets/Tests/EditMode/Editor/PixelArtGeneratorTests.cs`（画素図 → ピクセル配列の変換、不正文字は失敗）を先に書く
- [ ] T026 `game/Assets/Art/PixelMaps/*.txt` に 4 職・敵 4 種・マス・カーソル・UI 部品の画素図を作り、`PixelArtGenerator` で `game/Assets/Art/Sprites/` に PNG を生成する。`docs/assets-licenses.md` に「すべて自作」と記録する（憲法 X）
- [ ] T027 [P] `game/Assets/Tests/EditMode/Text/TextTableTests.cs`: 文言はキーで引く。キー未定義は例外でなく見つからない旨の結果を返す。`Strings.ja.json` のすべての値が日本語（ひらがな・カタカナ・漢字のいずれかを含む、または数字・記号のみ）であること。`TurnRpg.Game` の View のソースに UI 文言の文字列リテラルが直接書かれていないこと（FR-028）。**Red を確認する**
- [ ] T028 [P] `game/Assets/Scripts/Core/Text/TextTable.cs` と `game/Assets/StreamingAssets/GameData/Strings.ja.json`: 日本語の文言表（拒否理由、画面の見出し、操作ガイド、通知）。T027 を通す
- [ ] T029 `game/Assets/Scripts/Editor/SceneBuilder.cs`: Title・Preparation・Battle・Result のシーンと UI の骨組みをコードで生成する（`-executeMethod TurnRpg.EditorTools.SceneBuilder.BuildAll` でバッチ実行できる）。シーンと Prefab の YAML は手編集しない（憲法 VIII）。`docs/coverage-exclusions.md` に Editor 拡張として記載し、`tools/build-scenes.ps1` から実行できるようにする。骨組み（各シーンの共通部品・Canvas・EventSystem）をここで作り、各画面のタスク（US1・US3・US4）が、その画面の生成処理を `SceneBuilder` に追加する
- [ ] T030 [P] `game/Assets/Scripts/Game/Screens/ScreenFlow.cs` と `game/Assets/Scenes/Boot.unity`（T029 で生成）: タイトル → 準備 → 戦闘 → 結果の画面遷移の骨組み。`ScreenFlow` は現在の画面を保持し、テストから任意の画面を直接開始できる入口（`StartAt(...)`）を持つ
- [ ] T031 [P] `game/Assets/Tests/PlayMode/E2EFixture.cs` と `ScenarioAttribute.cs`: E2E 共通の準備（シーン読み込み、`InputTestFixture` による仮想 Keyboard/Mouse/Gamepad、固定シードの起動、フレーム待機ヘルパー）。`[Scenario("US1-AS1")]` 属性を定義する

**Checkpoint**: 土台が完成。T010〜T016・T027 が成功し、ユーザーストーリーの作業を始められる

---

## Phase 3: User Story 1 - 1回の戦闘を盤面上で戦い切る (Priority: P1) 🎯 MVP

**Goal**: 5x5 盤面で、味方フェーズ（移動と技）→ 敵フェーズ（素早さ順・盤面評価）を繰り返し、勝敗がつく

**Independent Test**: 固定の味方・敵編成とシードで戦闘を開始し、勝利と敗北の両方に到達できる

### Tests for User Story 1（先に書いて Red を確認）

- [ ] T032 [P] [US1] `game/Assets/Tests/EditMode/Battle/BoardOccupancyTests.cs`: 1 マスに存在できるユニットは 1 体、占有マス・盤面外への配置は拒否される（`Rejected(Occupied)`）
- [ ] T033 [P] [US1] `game/Assets/Tests/EditMode/Battle/MoveRuleTests.cs`: 同一フェーズに移動は 1 回まで（2 回目は `Rejected(AlreadyMoved)`）、盤面外・占有マスへは移動不可、移動と技の順序は自由、移動すると移動方向を向く
- [ ] T034 [P] [US1] `game/Assets/Tests/EditMode/Skills/SkillShapeTests.cs`: 向き（4 方向）に応じた範囲の回転。剣士「斬撃」前方 1 マス、「薙ぎ払い」前方の左・前・右、槍使い「突き」前方直線 2 マス、術士「火球」前方 2 マス先の十字 5 マス、「雷撃」前方直線 3 マス（data-model.md の全 12 基本技と 12 派生技）。盤面外のマスは切り捨てる。さらに、対象マス（data-model.md「対象マス」。範囲の中心線上で使用者から最も遠いマス）が全 24 技と敵の技で正しく計算されること、対象マスが盤面外になる方向は `Rejected(OutsideBoard)` になること、突進・猛進は進路上の占有マスの手前で止まり、移動の行動を消費しないこと
- [ ] T035 [P] [US1] `game/Assets/Tests/EditMode/Skills/DamageTests.cs`: ダメージ = 技の威力 + 攻撃者の攻撃 − 対象の防御、結果が 1 未満なら 1（FR-030）。`hp` が 0 になったら倒れて盤面から取り除かれる
- [ ] T036 [P] [US1] `game/Assets/Tests/EditMode/Skills/PushPullTurnTests.cs`: 導き手の押し出し・引き寄せ・向き変更。盤面外や占有マスへの押し出し・引き寄せは起きず、その効果は無効になる（行動は消費する）。氷結は素早さを 2、凍結は 4 下げる（戦闘終了まで持続、重複しない、最低値 1）。号令・采配は対象の向きを変え、次の技の威力を +2 / +4 する（鼓舞の札と加算、使用後に消える）
- [ ] T037 [P] [US1] `game/Assets/Tests/EditMode/Battle/PhaseTests.cs`: 味方フェーズ → 敵フェーズ → 味方フェーズ、フェーズ終了の選択、技の使用は同一フェーズ 1 回まで（`Rejected(AlreadyActed)`）、倒れたユニットは行動できない
- [ ] T038 [P] [US1] `game/Assets/Tests/EditMode/Battle/OutcomeTests.cs`: 敵全滅で `Won`、味方全滅で `Lost`（FR-011）、勝敗確定後のコマンドは拒否される
- [ ] T039 [P] [US1] `game/Assets/Tests/EditMode/Battle/PreviewTests.cs`: `PreviewMove` / `PreviewSkill` は予想される効果を返し、状態を変えない（FR-012）。キャンセルできる
- [ ] T040 [P] [US1] `game/Assets/Tests/EditMode/EnemyAi/EnemyOrderTests.cs`: 敵フェーズの行動順は素早さの高い順、同じ素早さは座標順（FR-031）
- [ ] T041 [P] [US1] `game/Assets/Tests/EditMode/EnemyAi/EnemyEvaluationTests.cs`: 斥候は体力の低い味方を優先、重装兵は最も近い味方、呪い手は隣接する味方が多い位置、ボスは隣接する味方が最も多い味方（同数なら体力が低い方）（FR-032）。同点は「移動先の座標順 → 技 ID 順 → 対象座標順」。乱数を使わず、同じ盤面から同じ行動を選ぶ。候補数の上限は 1,000 件
- [ ] T042 [P] [US1] `game/Assets/Tests/EditMode/Battle/BattleDeterminismTests.cs`: 同じ初期状態と同じ入力列から、イベント列が 100 回とも一致する（SC-004）
- [ ] T043 [P] [US1] `game/Assets/Tests/EditMode/Battle/TargetSelectionTests.cs`: 「技を選ぶ → 方向を選ぶ → 予告 → 確定」の状態遷移。キャンセルで 1 つ前に戻る。拒否された場合は選択状態を保って理由を返す。移動の選択（マスを選ぶ → 予告 → 確定）も同様。**Red を確認する**
- [ ] T044 [US1] `game/Assets/Tests/PlayMode/Battle/BattleE2ETests.cs`: US1 の E2E を、`[Scenario]` 付きで 1 シナリオ 1 テストとして書く。US1-AS1（味方が全員行動を終えると敵フェーズ）、US1-AS2（最後の敵を倒すと勝利）、US1-AS3（最後の味方が倒れると敗北）、US1-AS4（移動で移動の行動を消費）、US1-AS5（占有マス・盤面外の操作は拒否され理由が表示される）。固定シードの戦闘を `ScreenFlow.StartAt(Battle, fixture)` で開始し、キーボードの仮想入力で操作する。**この時点では View がないため失敗する（Red）**

### Implementation for User Story 1

- [ ] T045 [P] [US1] `game/Assets/Scripts/Core/Board/Board.cs`: 5x5、占有管理、`Place` / `MoveUnit`、範囲の取得。T032 を通す
- [ ] T046 [P] [US1] `game/Assets/Scripts/Core/Skills/SkillShape.cs` と `SkillResolver.cs`: 範囲の回転、ダメージ計算、押す・引く・向き変更・素早さ低下。T034〜T036 を通す
- [ ] T047 [US1] `game/Assets/Scripts/Core/Battle/Battle.cs`、`BattleState.cs`、`BattleEvents.cs`、`CommandResult.cs`: フェーズ制、`Move` / `UseSkill(unitId, skillId, direction)` / `EndAllyPhase` / `GetState` / `PreviewMove` / `PreviewSkill`、勝敗、イベント列。T033・T037〜T039 を通す
- [ ] T048 [US1] `game/Assets/Scripts/Core/EnemyAi/EnemyAi.cs`、`Evaluator.cs`、`EnemyPolicy.cs`: 候補の列挙、盤面評価、同点の固定順、候補数上限 1,000。T040・T041 を通す。敵フェーズを `Battle` から呼び出す
- [ ] T049 [US1] T042 の決定論テストを通し、`Battle` と `EnemyAi` に非決定的な要素がないことを確認する（失敗する場合は原因を直す）
- [ ] T050 [P] [US1] `game/Assets/Scripts/Game/Views/BoardView.cs` と `UnitView.cs`: Core の状態を読んでマスとユニット（体力・向き）を描く。状態が変わったときだけ更新する（毎フレームのメモリ確保なし）
- [ ] T051 [P] [US1] `game/Assets/Scripts/Game/Views/BattleHud.cs`: フェーズ表示、行動済みの印、勝敗の結果、拒否理由の日本語メッセージ、選択中のマスの枠（FR-028・FR-029）
- [ ] T052 [US1] `game/Assets/Scripts/Core/Battle/TargetSelection.cs`: 選択の状態機械（技 → 方向 → 予告 → 確定/キャンセル）。`Battle` のプレビューとコマンドを呼ぶ。T043 を通す
- [ ] T053 [US1] `game/Assets/Scripts/Game/Screens/BattleScreen.cs`: 入力（`Navigate` / `Submit` / `Cancel` / `EndPhase`）を `TargetSelection` に渡し、その結果の予告の表示とイベントの演出を行う（判断は持たない）。`game/Assets/Scenes/Battle.unity` は `SceneBuilder` に生成処理を追加して作る（手編集しない）
- [ ] T054 [US1] T044 の US1 の E2E を通す。失敗するシナリオは View の不足を直す
- [ ] T055 [US1] `pwsh tools/run-tests.ps1 -Platform EditMode -Coverage` と `pwsh tools/check-coverage.ps1` を実行し、US1 の範囲のカバレッジを確認する。Core の未到達の分岐に対応するテストを追加する

**Checkpoint**: 1 回の戦闘が単独で遊べ、テストで検証できる（MVP）

---

## Phase 4: User Story 2 - 技の連鎖で技が進化する (Priority: P1)

**Goal**: 味方同士の連続した技の対象マスが隣接（または同一）すると連鎖が成立し、連鎖に参加した技が派生技へ進化する

**Independent Test**: 連鎖が成立する組み合わせで進化し、成立しない順序では進化しない

### Tests for User Story 2（先に書いて Red を確認）

- [ ] T056 [P] [US2] `game/Assets/Tests/EditMode/Chain/ChainRuleTests.cs`: 次の技の対象マスが直前の対象マスに隣接（上下左右）または同一なら成立。斜めは不成立。技の種類・属性は判定に使わない。連鎖に含められる技は各味方 1 回、最大長 4
- [ ] T057 [P] [US2] `game/Assets/Tests/EditMode/Chain/ChainBaseCellTests.cs`: 直前の技が連鎖の基準として有効なのは、使用時に対象マスにいたユニットが解決後も生存している場合のみ。使用時に対象マスが空だった場合や、対象を倒した場合は基準にならず、次に使う技が新しい連鎖の最初の技になる。押し出し・引き寄せ（足払い・崩し・押し出し・突き飛ばし・引き寄せ・強引き）で対象が動かされても、生存していれば基準は有効で、基準のマスは使用時の対象マスのまま
- [ ] T058 [P] [US2] `game/Assets/Tests/EditMode/Chain/EvolutionTests.cs`: 連鎖の長さが 2 以上のとき、参加した技が技ごとに固定された派生技へ進化する。単独の技は進化しない。派生技は再進化しない。進化はフェーズ終了時に確定する。最後の敵を倒して戦闘が味方フェーズの途中で勝利に終わる場合も、勝利が確定した時点で進化を確定する。アイテムの使用は連鎖に含めない
- [ ] T059 [P] [US2] `game/Assets/Tests/EditMode/Chain/ChainResetTests.cs`: 味方フェーズの終了で連鎖状態がリセットされ（FR-015）、敵フェーズを挟んだ次の味方フェーズは新しい連鎖から始まる
- [ ] T060 [P] [US2] `game/Assets/Tests/EditMode/Chain/ChainEventsTests.cs`: `ChainFormed(length)`、`ChainBroken`、`SkillEvolved(from, to)` が発生順に出る
- [ ] T061 [US2] `game/Assets/Tests/PlayMode/Chain/ChainE2ETests.cs`: US2-AS1（つながる技で連鎖が成立し連鎖数が表示される）、US2-AS2（フェーズ終了で進化し、内容が示される）、US2-AS3（つながらない技では連鎖も進化も起きない）、US2-AS5（次の味方フェーズで連鎖状態がリセットされる）を `[Scenario]` 付きで書く。US2-AS4 は準備フェーズ（US3）と通しのラン（US4）が必要なため T084 で書く。**Red を確認する**

### Implementation for User Story 2

- [ ] T062 [US2] `game/Assets/Scripts/Core/Chain/ChainState.cs` と `ChainTracker.cs`: 技の使用記録 `(unitId, skillId, targetCell)`、`lastTargetCell`（使用時の対象マス）、基準の有効判定（使用時に対象マスにいたユニットが解決後も生存）、成立判定。同じ `unitId` は 2 回含まれない。T056・T057・T059 を通す
- [ ] T063 [US2] `game/Assets/Scripts/Core/Chain/EvolutionService.cs`: フェーズ終了時の進化の確定と `evolvedSkills` への記録。`Battle` に組み込む。T058・T060 を通す
- [ ] T064 [P] [US2] `game/Assets/Scripts/Game/Views/ChainHud.cs`: 連鎖数の表示、連鎖で光るマスの強調、進化の通知（日本語）
- [ ] T065 [US2] `BattleScreen.cs` に連鎖と進化のイベントを接続し、T061 の E2E を通す
- [ ] T066 [US2] カバレッジを再計測し（T055 と同じコマンド）、不足分のテストを追加する

**Checkpoint**: 連鎖進化が戦闘内で動く。US1 と US2 の両方が単独で検証できる

---

## Phase 5: User Story 3 - 準備フェーズで次戦に備える (Priority: P2)

**Goal**: 初期配置、技の編成、偵察、アイテム・装備の選択を行い、次の戦闘に反映する。戦闘中の消耗品の使用も含む

**Independent Test**: 準備フェーズで 4 つの操作をすべて行い、次戦の開始状態に反映される

### Tests for User Story 3（先に書いて Red を確認）

- [ ] T067 [P] [US3] `game/Assets/Tests/EditMode/Run/PlacementTests.cs`: 配置は自陣側（y=0〜1）の空きマスのみ（`Rejected(OutsideAllySide)` / `Rejected(Occupied)`）、4 人全員が配置されないと出撃できない。1 戦目の既定の配置は y=0 の行に左から剣士・槍使い・術士・導き手（x=0〜3）、2 戦目以降は前の戦闘の配置を引き継ぐ
- [ ] T068 [P] [US3] `game/Assets/Tests/EditMode/Run/LoadoutTests.cs`: 持ち込む技は 1 人あたり 2 つ。自分の職の基本技または進化済みの派生技のみ（`Rejected(SkillNotOwned)`）。進化済みの派生技が選べるようになっても元の基本技も選べる。選ばなかった技は戦闘で使えない
- [ ] T069 [P] [US3] `game/Assets/Tests/EditMode/Run/ScoutTests.cs`: 偵察は次戦の敵の種類・初期配置・方針の文を返し、具体的な次の行動は含まない（FR-020）
- [ ] T070 [P] [US3] `game/Assets/Tests/EditMode/Items/ItemTests.cs`: 回復薬は対象の体力を 12 回復（最大体力を超えない）、鼓舞の札は対象の次の技の威力を +4。ストック超過は `Rejected(InsufficientStock)`。使用は「技の使用」の行動を消費し、連鎖に含めない。使い切らなかった分は持ち越す
- [ ] T071 [P] [US3] `game/Assets/Tests/EditMode/Items/EquipmentTests.cs`: 装備は 1 人 1 つで、4 種すべてを最初から選べ、同じ装備を複数人に付けてもよい。鋼の刃（攻撃 +2）、厚い護符（防御 +2）、風の靴（素早さ +2）、命の石（最大体力 +6）が戦闘中に常時効く
- [ ] T072 [P] [US3] `game/Assets/Tests/EditMode/Run/HpCarryOverTests.cs`: 体力は戦闘をまたいで引き継がれる。準備フェーズ開始時に、生存者は最大体力の半分（端数切り上げ）回復し、最大体力を超えない。倒れた味方は最大体力の半分（端数切り上げ）で復帰する（FR-033）
- [ ] T073 [US3] `game/Assets/Tests/PlayMode/Preparation/PreparationE2ETests.cs`: US3-AS1（配置が次戦の開始時に反映される）、US3-AS2（選んだ技だけが次戦で使える）、US3-AS3（偵察情報が一部だけ表示される）、US3-AS4（アイテム・装備が次戦で反映される）、US3-AS5（自陣側以外への配置は拒否される）を `[Scenario]` 付きで書く。**Red を確認する**

### Implementation for User Story 3

- [ ] T074 [P] [US3] `game/Assets/Scripts/Core/Run/Preparation.cs`: `Place` / `SetLoadout` / `SetEquipment` / `SetItems` / `GetScout` / `Start`（contracts/core-api.md）。T067〜T069 を通す
- [ ] T075 [P] [US3] `game/Assets/Scripts/Core/Items/Inventory.cs`、`ItemEffects.cs`、`Equipment.cs`: 消耗品のストック、効果、装備補正。`Battle.UseItem` を追加する。T070・T071 を通す
- [ ] T076 [US3] `game/Assets/Scripts/Core/Run/HpRecovery.cs`: 準備フェーズ開始時の回復と復帰。T072 を通す
- [ ] T077 [P] [US3] `game/Assets/Scripts/Game/Screens/PreparationScreen.cs` と `game/Assets/Scenes/Preparation.unity`（`SceneBuilder` に生成処理を追加）: タブ（配置・技・偵察・持ち物）、`NextTab` / `PrevTab`、日本語の説明文（向きは敵側固定で選ばせない）
- [ ] T078 [P] [US3] `game/Assets/Scripts/Game/Views/ScoutView.cs`、`LoadoutView.cs`、`InventoryView.cs`: 各タブの表示
- [ ] T079 [US3] 戦闘画面に消耗品の使用（`UseItem`）の操作と表示を追加する（`BattleScreen.cs`）
- [ ] T080 [US3] T073 の E2E を通す。カバレッジを再計測し、不足分のテストを追加する

**Checkpoint**: 準備フェーズの 4 つの操作が動き、次戦へ反映される

---

## Phase 6: User Story 4 - 5戦のランを通して遊び、ボスを倒してクリアする (Priority: P2)

**Goal**: シードつきでランを開始し、準備フェーズを挟んで 5 戦（最後はボス）を進め、クリアか全滅で終える

**Independent Test**: シードを指定してランを開始し、5 戦をクリアまたは全滅で終える

### Tests for User Story 4（先に書いて Red を確認）

- [ ] T081 [P] [US4] `game/Assets/Tests/EditMode/Run/RunFactoryTests.cs`: `Run.Start(seed?)`。シードは 0〜2,147,483,647 の整数のみ有効で、範囲外は `Rejected(InvalidSeed)`。未指定は実行時に決める。5 戦分の敵編成を決め、5 戦目は必ずボス。1〜4 戦目は通常の敵を 2〜4 体、5 戦目はボス 1 体と取り巻き 2 体（通常の敵）
- [ ] T082 [P] [US4] `game/Assets/Tests/EditMode/Run/RunProgressTests.cs`: 戦闘ごとに準備フェーズを挟む（FR-003）、勝利で次の戦闘へ、ボス撃破で `Cleared`、全滅で `Defeated`、ラン終了で進化済みの技などのランの状態を破棄する（FR-017）。戦闘に勝つたび回復薬が 1 個補充される（上限 4）
- [ ] T083 [P] [US4] `game/Assets/Tests/EditMode/Run/RunDeterminismTests.cs`: 同じシードと同じ入力列でランを 100 回実行した結果（敵編成・戦闘結果・進化結果）がすべて一致する（SC-004）。シードが異なれば編成が変わりうる
- [ ] T084 [US4] `game/Assets/Tests/PlayMode/Run/RunE2ETests.cs`: US4-AS1（新しいランが準備フェーズから始まり 1 戦目の敵が決まる）、US4-AS2（同じシードと入力で結果が同一）、US4-AS3（ボス撃破でクリア画面）、US4-AS4（全滅でラン終了画面、状態は破棄）、US4-AS5（タイトルに戻ると中断セーブがなく新しいランを始められる）を `[Scenario]` 付きで書く。さらに **US2-AS4**（進化後の技が次の準備フェーズの編成に表示される）をここで書く。**Red を確認する**

### Implementation for User Story 4

- [ ] T085 [P] [US4] `game/Assets/Tests/EditMode/Run/ChainOpportunityTests.cs`: 代表シード 1〜50 の各戦闘で、味方の既定の編成から、2 技以上の連鎖が成立する行動列が存在することを、上限つきの探索（候補数・深さの上限を明記）で確認する（SC-006）。**Red を確認する**
- [ ] T086 [US4] `game/Assets/Tests/PlayMode/Run/FullRunBotE2ETests.cs`: 決定論的なボット（T087）が、仮想ゲームパッド入力で、シード固定のランを 1 戦目の準備フェーズからクリアまたは全滅のラン終了画面まで、UI 経由で通す。結果が 2 回の実行で一致することも確認する（憲法 III の「ラン終了」までの通し）。**Red を確認する**
- [ ] T087 [US4] `game/Assets/Tests/PlayMode/Support/AutoPlayerBot.cs`: Core の状態と `EnemyAi` の評価関数を使って味方の行動を決め、仮想入力のイベント列に変換するテスト用ボット（乱数なし）
- [ ] T088 [US4] `game/Assets/Scripts/Core/Run/Run.cs`、`RunFactory.cs`、`RunStatus.cs`、`EnemyComposer.cs`: シードから戦闘ごとのシードと敵編成を決める（PCG32 の `Derive` を使用）。T081〜T083 を通す
- [ ] T089 [US4] `game/Assets/Scripts/Core/Run/RunFlow.cs`: 準備 → 戦闘 → 結果の遷移、勝利後の補充、ラン終了時の破棄。`Preparation.Start()` から `Battle` を生成する
- [ ] T090 [P] [US4] `game/Assets/Scripts/Game/Screens/TitleScreen.cs` と `game/Assets/Scenes/Title.unity`（T029 の SceneBuilder で生成）: 「新しいラン」（シード入力欄・無効値の理由表示）、「続きから」は US5 で追加
- [ ] T091 [P] [US4] `game/Assets/Scripts/Game/Screens/ResultScreen.cs` と `game/Assets/Scenes/Result.unity`（`SceneBuilder` に生成処理を追加）: クリア画面・ラン終了画面。「タイトルへ」の操作
- [ ] T092 [US4] `ScreenFlow.cs` に実際のラン進行を接続し、T084 の E2E（US4-AS1〜AS5、US2-AS4）と T085・T086 を通す。T085 が失敗する場合は、敵の構成か技のデータ（`GameData`）を調整する
- [ ] T093 [US4] カバレッジを再計測し、不足分のテストを追加する

**Checkpoint**: 1 回の通しプレイが完走できる

---

## Phase 7: User Story 5 - 途中で中断して再開する (Priority: P3)

**Goal**: 準備フェーズの開始時に自動保存し、再起動後に続きから再開できる。破損しても落ちない

**Independent Test**: 準備フェーズでアプリを終了し、再起動後に続きから再開できる

### Tests for User Story 5（先に書いて Red を確認）

- [ ] T094 [P] [US5] `game/Assets/Tests/EditMode/Save/SaveCodecTests.cs`: contracts/save-format.md のスキーマで `Encode` / `Decode` の往復が一致する。`schemaVersion` は 1、`seed` は 0〜2,147,483,647、`battleIndex` は 1〜5、`status` は保存時 `Preparing`、`battleSeeds` は長さ 5、`allies` は長さ 4で職は重複しない、`allies[].hp` は 1〜最大体力、`loadout` は長さ 2で所持する技のみ、`startCell` は自陣側（y=0〜1）で重複なし、`evolvedSkills` はデータ定義に存在する派生技のみ、`inventory` の各数は 0〜`maxStock`
- [ ] T095 [P] [US5] `game/Assets/Tests/EditMode/Save/SaveFailureTests.cs`: 形式不正・検証失敗・ハッシュ不一致は `Corrupted`、未知の `schemaVersion` は `VersionMismatch`、ファイルなしは `NotFound`。`Decode` は例外を投げず結果型で返す（FR-025）
- [ ] T096 [P] [US5] `game/Assets/Tests/EditMode/Save/ResumeTests.cs`: 保存した準備フェーズの状態が `Run.TryResume` で 100% 同じに復元される（SC-007）。ラン終了で `Run.Discard` により削除される（FR-024）。`FakeSaveStore` を使う
- [ ] T097 [P] [US5] `game/Assets/Tests/EditMode/Infrastructure/FileSaveStoreTests.cs`: 一時ファイルに書き、検証して読み戻してから置換する。置換前に失敗しても直前の保存が残る（強制終了の模擬）。一時ディレクトリを使う
- [ ] T098 [US5] `game/Assets/Tests/PlayMode/Save/SaveE2ETests.cs`: US5-AS1（準備フェーズで終了して再起動すると「続きから」で同じ準備フェーズが再現される）、US5-AS2（戦闘の途中で終了すると直前の準備フェーズ開始時点から再開される）、US5-AS3（破損したセーブで「続きから」を選ぶと通知が出て新しいランを始められ、ゲームは落ちない）を `[Scenario]` 付きで書く。再起動はシーンの破棄と再読み込みで模擬する。**Red を確認する**

### Implementation for User Story 5

- [ ] T099 [US5] `game/Assets/Scripts/Core/Save/SaveCodec.cs`、`SaveDto.cs`、`SaveResult.cs`、`ISaveStore.cs`、`FakeSaveStore.cs`: 直列化、版数、ハッシュ、検証。`Run.TryResume` / `Run.Discard` を追加する。T094〜T096 を通す
- [ ] T100 [US5] `game/Assets/Scripts/Game/Infrastructure/FileSaveStore.cs`: `<persistentDataPath>/run-save.json` の一時ファイル経由の置換。T097 を通す
- [ ] T101 [US5] `RunFlow.cs` に準備フェーズ開始時の自動保存（FR-023）とラン終了時の削除を接続する。`TitleScreen.cs` に「続きから」と破損・版数不一致の日本語の通知を追加する
- [ ] T102 [US5] T098 の E2E を通す。カバレッジを再計測し、不足分のテストを追加する

**Checkpoint**: 中断・再開が動き、破損にも耐える

---

## Phase 8: User Story 6 - キーボード・マウス・ゲームパッドで同じ操作ができる (Priority: P2)

**Goal**: 3 デバイスで全操作が同等にでき、最後に操作したデバイスに自動で切り替わる

**Independent Test**: 3 デバイスそれぞれで、ランの開始から 1 戦闘の勝利までを完了できる

### Tests for User Story 6（先に書いて Red を確認）

- [ ] T103 [P] [US6] `game/Assets/Tests/EditMode/Input/InputModeTrackerTests.cs`: 最後に操作したデバイスが有効になる、マウスを動かすとマウス操作へ・キーボード/ゲームパッドの入力でフォーカス操作へ切り替わる、切替時に選択中の項目・マスが保たれる、接続中のデバイスが切断されても他のデバイスで継続できる
- [ ] T104 [US6] `game/Assets/Tests/PlayMode/Input/InputE2ETests.cs`: US6-AS1（ゲームパッドの方向入力と決定・キャンセルで、キーボード・マウスと同じ操作がすべてできる）、US6-AS2（ゲームパッド操作中にマウスを動かすとマウス操作に切り替わり、選択状態が保たれる）、US6-AS3（どのデバイスで選んでも、選択中のマスが画面上で明確に分かる）を `[Scenario]` 付きで書く
- [ ] T105 [US6] `game/Assets/Tests/PlayMode/Input/DeviceFullFlowE2ETests.cs`: キーボード、マウス、ゲームパッドのそれぞれで、ランの開始（固定シード）から 1 戦闘の勝利までを完了する通しの E2E（SC-005）。**Red を確認する**

### Implementation for User Story 6

- [ ] T106 [P] [US6] `game/Assets/Tests/PlayMode/Input/HelpBarE2ETests.cs`: 各画面（タイトル・準備・戦闘・結果）に操作ガイドが日本語で表示され、最後に操作したデバイスに合わせて内容が切り替わる（FR-034）。ガイドの文言は `TextTable` 経由。**Red を確認する**
- [ ] T107 [US6] `game/Assets/Scripts/Core/Input/InputModeTracker.cs`: デバイス種別のイベントを受けて有効なデバイスと「選択状態」を管理する純粋なロジック。T103 を通す
- [ ] T108 [US6] `game/Assets/Scripts/Game/Input/InputRouter.cs` と各画面（`TitleScreen`、`PreparationScreen`、`BattleScreen`、`ResultScreen`）にフォーカス移動、マウスのポインタ操作、切替時の選択保持、切断時の継続を実装する
- [ ] T109 [US6] `game/Assets/Scripts/Game/Views/HelpBar.cs`: 画面下部の操作ガイド。`InputModeTracker` の有効なデバイスに応じて、`TextTable` の文言（例: 「A: 決定  B: 戻る」「Enter: 決定  Esc: 戻る」）を切り替える。T106 を通す
- [ ] T110 [US6] 選択中のマスの枠と色を、デバイスによらず同じ見た目にする（`BoardView.cs`、`BattleHud.cs`）
- [ ] T111 [US6] T104・T105 の E2E を通す。カバレッジを再計測し、不足分のテストを追加する

**Checkpoint**: 3 デバイスで同じ操作ができる

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: 品質ゲート、性能、ドキュメント、レビュー

- [ ] T112 [P] `game/Assets/Tests/PlayMode/Performance/AllocationTests.cs`: 戦闘画面で一定時間、毎フレームの GC 確保が 0 バイトであることを確認する（憲法 IX）。違反があれば該当の `Update` を直す。あわせて、通しの E2E 中のフレーム時間を記録し、60 fps（16.7 ms/フレーム）を大きく下回らないことを確認する
- [ ] T113 [P] `game/Assets/Tests/EditMode/EnemyAi/EnemyAiPerformanceTests.cs`: 最悪の盤面で敵 1 体の行動判断が 50 ms 以内に終わる（plan.md の性能目標）
- [ ] T114 `docs/coverage-exclusions.md` を最終確認する。除外が View・MonoBehaviour・自動生成コード・Editor 拡張だけで、ロジックが含まれていないことをレビューする
- [ ] T115 `pwsh tools/run-tests.ps1 -Platform EditMode -Coverage` → `pwsh tools/check-coverage.ps1` を実行し、`TurnRpg.Core` のラインカバレッジが **90% 以上**であることを確認する。未達なら不足分のテストを追加する（SC-009）。PlayMode でしか通らない Core のコードが原因なら、`-Platform PlayMode -Coverage` の結果も合算して判定する
- [ ] T116 `pwsh tools/run-tests.ps1 -Platform PlayMode` を実行し、`ScenarioTraceabilityTests` を含む全テストが成功することを確認する。`docs/e2e-traceability.md` を再生成する（SC-008、全 26 シナリオ）
- [ ] T117 [P] SC-001〜SC-003（初回の操作時間、1 戦闘の長さ、1 ラン 25 分以内）を、操作ガイドを表示した状態で手動で測り、結果を `docs/playtest-notes.md` に記録する。基準を満たさない場合は数値データ（`GameData/*.json`）を調整する
- [ ] T118 quickstart.md の手順 1〜6 を実行して確認し、差異があれば quickstart.md を直す
- [ ] T119 `code-reviewer` エージェントで全差分をレビューし、重大・要修正の指摘を直す
- [ ] T120 `/speckit-analyze` を実行し、仕様・計画・タスクの不整合に重大な指摘がないことを確認する（憲法の品質ゲート）
- [ ] T121 `docs/assets-licenses.md` をすべての素材（ドット絵）が「自作」と記録されていることで最終確認する（憲法 X）

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: すぐ開始できる
- **Foundational (Phase 2)**: Setup の完了後。全ユーザーストーリーをブロックする
- **US1 (Phase 3)**: Foundational の後。他のストーリーに依存しない（MVP）
- **US2 (Phase 4)**: US1 の `Battle` に連鎖を組み込むため US1 の後。E2E の US2-AS4 だけは US4 で書く
- **US3 (Phase 5)**: US1 の `Battle` に `UseItem` を追加するため US1 の後。US2 とは独立
- **US4 (Phase 6)**: US1・US3 の後（準備 → 戦闘の遷移が必要）。US2-AS4 の E2E は US2 と US3 の後
- **US5 (Phase 7)**: US4 の `Run` に依存する
- **US6 (Phase 8)**: 入力の土台は Foundational にある。通しの E2E（T105）は US4 の後
- **Polish (Phase 9)**: 必要なストーリーがすべて終わった後

### 推奨順

Setup → Foundational → US1 → US2 → US3 → US4 → US5 → US6 → Polish（P1 の US1・US2 を先に完成させ、そのあと P2・P3）

### Within Each User Story

- テスト（Red を確認）→ Core の実装（Green）→ リファクタリング → View と E2E（Green）の順
- Core のモデル → サービス → 画面の順
- ストーリーのカバレッジを確認してから次へ進む

### Parallel Opportunities

- Phase 1: T002、T005、T007、T008
- Phase 2: テスト T010〜T016・T027 はすべて並列。実装 T017〜T020 も並列（別ファイル）
- 各ストーリーの EditMode テスト（`[P]` 付き）は並列。Core の実装も、別ファイルなら並列
- 画面ごとの View（`[P]` 付き）は並列

---

## Parallel Example: User Story 1

```text
# US1 の EditMode テストを一緒に書く（別ファイル）:
Task: T032 BoardOccupancyTests.cs
Task: T034 SkillShapeTests.cs
Task: T035 DamageTests.cs
Task: T040 EnemyOrderTests.cs
Task: T041 EnemyEvaluationTests.cs

# Core の実装を一緒に進める:
Task: T045 Board.cs
Task: T046 SkillShape.cs / SkillResolver.cs

# View を一緒に進める:
Task: T050 BoardView.cs / UnitView.cs
Task: T051 BattleHud.cs
```

---

## Implementation Strategy

### MVP First（US1 のみ）

1. Phase 1: Setup（バッチモードのテスト・カバレッジが動くことを最初に確認する）
2. Phase 2: Foundational
3. Phase 3: US1
4. **停止して検証**: 1 回の戦闘が遊べ、US1 の E2E と EditMode が成功する

### Incremental Delivery

1. Setup + Foundational → 土台
2. US1 → 戦闘が成立（MVP）
3. US2 → 連鎖進化（本作の新しさの核）
4. US3 → 準備フェーズ
5. US4 → 通しのラン
6. US5 → 中断・再開
7. US6 → 入力の同等性
8. Polish → 品質ゲート（カバレッジ 90%、全 26 シナリオの E2E）

---

## Notes

- [P] = 別ファイルで依存なし
- [Story] ラベルはトレーサビリティのため
- 各ストーリーは単独で完了・検証できる
- テストが失敗（Red）してから実装する。Red の確認を省略しない
- `.meta`、`Library/`、`Temp/`、シーンや Prefab の YAML は手編集しない（憲法 VIII）。シーンの作成と編集はエディタの操作またはスクリプトで行う
- 数値（威力・能力値・補充量）は `GameData/*.json` で調整し、コードに直書きしない
- タスクごと、または論理的なまとまりごとにコミットする（テストのコミットが実装より先）
