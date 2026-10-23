# Contract: 中断セーブのフォーマット

準備フェーズの開始時に自動保存する（FR-023）。ランの終了で削除する（FR-024）。保存先は 1 ファイルのみ（メタ進行なし、FR-026）。

## 保存先

`<persistentDataPath>/run-save.json`（一時ファイル `run-save.json.tmp` に書き、検証後に置換する）。

## スキーマ（JSON）

```json
{
  "schemaVersion": 1,
  "seed": 123456,
  "battleIndex": 2,
  "status": "Preparing",
  "battleSeeds": [111, 222, 333, 444, 555],
  "allies": [
    {
      "jobId": "swordsman",
      "hp": 18,
      "equipmentId": "steel-blade",
      "loadout": ["slash", "sweep"],
      "startCell": { "x": 1, "y": 0 }
    }
  ],
  "evolvedSkills": ["slash-chain"],
  "inventory": { "potion": 2, "morale-card": 1 },
  "checksum": "<保存内容の検証用ハッシュ>"
}
```

| 項目 | 型 | 制約 |
|------|----|------|
| `schemaVersion` | 整数 | 現在は 1。未知の版は `VersionMismatch` |
| `seed` | 整数 | 0〜2,147,483,647 |
| `battleIndex` | 整数 | 1〜5 |
| `status` | 文字列 | 保存時は常に `Preparing` |
| `battleSeeds` | 整数配列 | 長さ 5 |
| `allies` | 配列 | 長さ 4。職は重複しない |
| `allies[].hp` | 整数 | 1〜最大体力（準備フェーズ開始時の回復後の値） |
| `allies[].equipmentId` | 文字列または null | null は装備なし。指定する場合はデータ定義に存在する装備 |
| `allies[].loadout` | 文字列配列 | 長さ 2。所持する技のみ |
| `allies[].startCell` | 座標 | 自陣側（y=0〜1）、重複なし |
| `evolvedSkills` | 文字列配列 | データ定義に存在する派生技のみ |
| `inventory` | 連想配列 | 各数が 0〜`maxStock` |
| `checksum` | 文字列 | `checksum` を除く内容のハッシュ。不一致は `Corrupted` |

## 読み込みの失敗

| 状態 | 結果 | 画面の動作 |
|------|------|------------|
| ファイルがない | `NotFound` | 「続きから」を出さない |
| 形式不正・検証失敗・ハッシュ不一致 | `Corrupted` | 破損を通知し、新しいランを始められる（FR-025）。ゲームを終了しない |
| 未知の `schemaVersion` | `VersionMismatch` | 同様に通知して新しいランを始められる |

壊れたファイルは自動では削除しない（新しいランの開始時に上書きされる）。

## 版数の方針

スキーマを変更するときは `schemaVersion` を上げ、古い版の読み込み可否を明記する。この縦切りでは古い版は存在しない。
