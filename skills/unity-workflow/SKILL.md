---
name: unity-workflow
description: Unity プロジェクトで機能を追加・修正するときの手順。Unity の C# スクリプトを作成・変更するときに使う。
when_to_use: Unity の機能追加、バグ修正、MonoBehaviour や ScriptableObject の作成を頼まれたとき。
argument-hint: "[作りたい機能や直したい不具合]"
---

# Unity 作業手順

依頼内容: $ARGUMENTS

1. **調査**: `Assets/` の中から関係するスクリプト、Prefab、ScriptableObject を探す。
2. **設計**: どの GameObject にどのコンポーネントを付けるかを決めて、ユーザーに伝える。
3. **実装**: `unity-specialist` の方針に沿って C# を書く。
   - 新しいスクリプトはクラス名とファイル名を同じにする。
   - 名前空間がある場合は既存のものに合わせる。
4. **エディタでの作業を伝える**: コンポーネントの付け方、インスペクターで設定する値などを手順として書く。
5. **確認**: コンパイルエラーが出ないか、Play モードで確認する手順を伝える。
6. **レビュー**: `code-reviewer` で変更を確認する。
