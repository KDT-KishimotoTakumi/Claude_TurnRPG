# SessionStart フック: プロジェクトのエンジンを判別し、使うべきエージェントを Claude に伝える。
# 標準出力は Claude の文脈に追加される。

$root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$engines = @()

if ((Test-Path (Join-Path $root 'Assets')) -and (Test-Path (Join-Path $root 'ProjectSettings'))) {
    $engines += 'Unity: 実装・修正・デバッグは unity-specialist に委譲する。'
}

if (Get-ChildItem -Path $root -Filter '*.uproject' -File -ErrorAction SilentlyContinue) {
    $engines += 'Unreal Engine: 実装・修正・デバッグは unreal-specialist に委譲する。'
}

$dxlib = Get-ChildItem -Path $root -Recurse -Include '*.cpp', '*.h' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\(Library|Temp|Binaries|Intermediate|Saved|node_modules|\.git)\\' } |
    Select-Object -First 300 |
    Select-String -Pattern 'DxLib\.h' -List -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($dxlib) {
    $engines += 'DXライブラリ: 実装・修正・デバッグは dxlib-specialist に委譲する。'
}

if ($engines.Count -eq 0) {
    Write-Output 'ゲームエンジンを判別できなかった。まず game-explorer でプロジェクト構成を調べる。'
    exit 0
}

Write-Output '## 検出したエンジンとエージェントの使い分け'
$engines | ForEach-Object { Write-Output "- $_" }
Write-Output '- 構成や処理の流れの調査は game-explorer に委譲する。'
Write-Output '- コードを変更したら、完了を報告する前に code-reviewer でレビューする。'
