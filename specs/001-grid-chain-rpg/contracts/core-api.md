# Contract: Core API（View が使う操作とイベント）

`TurnRpg.Core` が View（`TurnRpg.Game`）に公開する境界。View は状態を読み、コマンドを呼ぶだけで、判断を持たない。

## 原則

- Core は `UnityEngine` を参照しない。
- 時刻、ファイル、乱数は Core の抽象（`IRandom`, `ISaveStore`, `IDataSource`）を通して注入する。
- コマンドは不正なら例外ではなく `CommandResult`（`Ok` / `Rejected(reason)`）を返す。`reason` は日本語の表示文言に変換できる列挙値。

## ランの管理

| 操作 | 入力 | 結果 |
|------|------|------|
| `Run.Start(seed?)` | シード（省略可。範囲 0〜2,147,483,647） | `Run`（`Preparing`、戦闘 1）。範囲外は `Rejected(InvalidSeed)` |
| `Run.TryResume(store)` | 保存ストア | `Resumed(run)` または `Failed(reason)`（`Corrupted` / `VersionMismatch` / `NotFound`） |
| `Run.Discard(store)` | 保存ストア | 中断セーブの削除 |

## 準備フェーズ

| 操作 | 内容 |
|------|------|
| `Preparation.Place(unitId, cell)` | 自陣側の空きマスへの配置。向きは敵側（上向き）で固定（違反は `Rejected(OutsideAllySide)` / `Rejected(Occupied)`） |
| `Preparation.SetLoadout(unitId, skillIds[2])` | 持ち込む技の選択（所持していない技は `Rejected(SkillNotOwned)`） |
| `Preparation.SetEquipment(unitId, equipmentId)` | 装備の選択（1 人 1 つ） |
| `Preparation.SetItems(itemId, count)` | 持ち込む消耗品（ストック超過は `Rejected(InsufficientStock)`） |
| `Preparation.GetScout()` | 次戦の偵察情報（種類、初期配置、方針の文） |
| `Preparation.Start()` | 出撃。`Battle` を返し、`InBattle` に遷移 |

## 戦闘

| 操作 | 内容 |
|------|------|
| `Battle.PreviewMove(unitId, cell)` / `PreviewSkill(unitId, skillId, direction)` | 確定前の効果の予告（FR-012）。状態は変えない。予告には確定する対象マスと影響を受けるマスを含む |
| `Battle.Move(unitId, cell)` | 移動。同フェーズ 2 回目は `Rejected(AlreadyMoved)` |
| `Battle.UseSkill(unitId, skillId, direction)` | 技の使用。方向（上下左右）だけを指定し、対象マスは技の範囲から自動で決まる（data-model.md「対象マス」）。同フェーズ 2 回目は `Rejected(AlreadyActed)`、対象マスが盤面外になる方向は `Rejected(OutsideBoard)` |
| `Battle.UseItem(unitId, itemId, targetUnitId)` | 消耗品の使用。「技の使用」の行動を消費。連鎖に含めない |
| `Battle.EndAllyPhase()` | 味方フェーズの終了。連鎖の進化を確定し、敵フェーズを実行 |
| `Battle.GetState()` | 盤面、ユニット、フェーズ、連鎖状態の読み取り専用スナップショット |

### イベント（View の演出と E2E の検証に使う）

`UnitMoved`, `SkillUsed(unitId, skillId, direction, targetCell)`, `DamageDealt`, `UnitDefeated`, `ChainFormed(length)`, `ChainBroken`, `SkillEvolved(from, to)`, `PhaseChanged`, `BattleWon`, `BattleLost`

イベントは発生順に、同じ入力から同じ列が得られる（決定論）。

## 保存

| 操作 | 内容 |
|------|------|
| `ISaveStore.Write(bytes)` | 一時ファイルに書いて検証後に置換する実装は Game 側 |
| `ISaveStore.Read()` | 保存データのバイト列または欠落の通知 |
| `SaveCodec.Encode(run)` / `Decode(bytes)` | Core 側の直列化。`Decode` は失敗を結果型で返し、例外を投げない |

## テスト容易性

- `FakeSaveStore`（メモリ上）と `FixedRandom` を Core のテスト用に提供する。
- E2E は Game のシーンを実際に起動し、仮想入力デバイスで操作する。
