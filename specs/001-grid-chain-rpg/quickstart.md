# Quickstart: 検証手順

実装後に、機能が仕様どおりに動くことを確かめる手順。詳細な型は [data-model.md](data-model.md)、操作の境界は
[contracts/core-api.md](contracts/core-api.md) を参照。

## 前提

- Unity 6000.0.42f1 が `C:\Program Files\Unity\Hub\Editor\6000.0.42f1\` にある。
- PowerShell 7+。
- プロジェクトは `game/`。パスが日本語のため、初回は手順 1 でバッチモードが動くことを必ず確認する。

## 手順

### 1. 環境の確認（バッチモードの起動）

```powershell
pwsh tools/run-tests.ps1 -Platform EditMode
```

期待: Unity がエラーなく起動し、テストが実行されて結果ファイルが出力される。失敗する場合は日本語パスが原因の可能性があるため、
ASCII のパスへのジャンクションを使う（research.md R-11）。

### 1b. シーンの生成（シーンがない新規環境のみ）

```powershell
pwsh tools/build-scenes.ps1
```

期待: `game/Assets/Scenes/` に Boot・Title・Preparation・Battle・Result が生成される（`SceneBuilder` が実行される。手編集しない）。

### 2. ユニットテスト（Core）

```powershell
pwsh tools/run-tests.ps1 -Platform EditMode
```

期待: すべて成功。

### 3. カバレッジ（品質ゲート）

```powershell
pwsh tools/run-tests.ps1 -Platform EditMode -Coverage
pwsh tools/check-coverage.ps1
```

期待: `TurnRpg.Core` のラインカバレッジが 90% 以上で、終了コードが 0。90% 未満なら非ゼロで終了する。
除外一覧（`docs/coverage-exclusions.md`）が View・MonoBehaviour・自動生成コードだけであることを確認する。

### 4. E2E テスト

```powershell
pwsh tools/run-tests.ps1 -Platform PlayMode
```

期待: すべて成功。EditMode の整合性テスト（`ScenarioTraceabilityTests`）が、仕様書のすべての受け入れシナリオ
（US1-AS1 〜 US6-AS3）に対応する E2E があることを確認する。

### 5. 通しプレイの手動確認（シード固定）

1. Unity エディタで `game/` を開き、`Assets/Scenes/Title.unity` を再生する。
2. 「新しいラン」でシード `12345` を指定する。
3. 準備フェーズで、配置・技の編成・偵察・アイテム選択を行い、出撃する。
4. 連鎖が成立する順序で技を使い、進化が表示されることを確認する。
5. 5 戦を進めるか全滅して、クリア画面またはラン終了画面を確認する。
6. 準備フェーズでゲームを終了し、再起動して「続きから」で復帰できることを確認する。
7. キーボード、マウス、ゲームパッドのそれぞれで同じ操作ができることを確認する。

### 6. 決定論の確認

```powershell
pwsh tools/run-tests.ps1 -Platform EditMode -Filter DeterminismTests
```

期待: 同じシードと入力列で 100 回実行した結果がすべて一致する（SC-004）。

## 合格条件

- 手順 2・3・4 がすべて成功し、カバレッジが 90% 以上。
- すべての受け入れシナリオに E2E がある。
- 手順 5 の手動確認で、仕様の主要な流れが再現できる。
