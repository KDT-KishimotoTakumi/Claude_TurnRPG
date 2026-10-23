# Hermes Agent 向けの導入（引数が `hermes` のとき）

手順1は `SKILL.md` と同じです。手順2以降を次のように置き換えます。

## 手順2: 導入

```
specify init --here --integration hermes --force --non-interactive
```

`.specify/` と `.hermes/skills/`（空のマーカーディレクトリ）が作られます。CLI は speckit-* スキルを `~/.hermes/skills/` に書き込みます。

## 手順3: スキルの配置先を修正（必須）

Hermes が読む skills ディレクトリは環境ごとに異なります。次の優先順で解決します。

1. 環境変数 `HERMES_HOME` が設定されていれば `$HERMES_HOME/skills`
2. 未設定なら `hermes config path` の出力（config.yaml の所在）の親ディレクトリの `skills/`
3. それも不明なら `~/.hermes/skills`

`~/.hermes/skills` の `speckit-*` を、解決した配置先へコピーします。

```python
import os, shutil, subprocess, pathlib

src_root = os.path.expanduser("~/.hermes/skills")   # 手順2が書き込んだ場所
dst_root = None
if os.environ.get("HERMES_HOME"):
    dst_root = pathlib.Path(os.environ["HERMES_HOME"]) / "skills"
else:
    try:
        cfg = subprocess.run(["hermes", "config", "path"], capture_output=True,
                             text=True, timeout=30).stdout.strip()
        if cfg:
            dst_root = pathlib.Path(cfg).parent / "skills"
    except Exception:
        pass
if not dst_root:
    dst_root = pathlib.Path.home() / ".hermes" / "skills"

for d in sorted(os.listdir(src_root)):
    if d.startswith("speckit-"):
        s, t = os.path.join(src_root, d), str(dst_root / d)
        if os.path.exists(t): shutil.rmtree(t)
        shutil.copytree(s, t)
print("dst_root:", dst_root)
```

## 手順4: 検証

1. `hermes skills list` で、`speckit-` で始まる10個（analyze / checklist / clarify / constitution / converge / implement / plan / specify / tasks / taskstoissues）がすべて `enabled` で表示される。表示されない場合は手順3の配置先の解決が間違っている。
2. `dst_root` 配下の各 `speckit-*/SKILL.md` に未処理プレースホルダー（`{SCRIPT}` / `{ARGS}` / `__SPECKIT_COMMAND_*__` / `__AGENT__`）が残っていない。残っていれば手順2からやり直す。
3. スキル本文に、Windows では `.specify/scripts/powershell/*.ps1`、Linux/macOS では `.specify/scripts/bash/*.sh` が埋め込まれている。
4. `.specify/integration.json` の `installed_integrations` に `hermes` が含まれる。
5. `SKILL.md` の手順3-4 と同じ前提スクリプトが起動する。

スキルは次回セッションから有効です。既存セッションでは `/reset` が必要です。
