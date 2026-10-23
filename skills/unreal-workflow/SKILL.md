---
name: unreal-workflow
description: Unreal Engine プロジェクトで機能を追加・修正するときの手順。UE の C++ クラスを作成・変更するときに使う。
when_to_use: Unreal Engine の機能追加、バグ修正、Actor や Component の作成を頼まれたとき。
argument-hint: "[作りたい機能や直したい不具合]"
---

# Unreal Engine 作業手順

依頼内容: $ARGUMENTS

1. **調査**: `Source/<モジュール名>/` と `*.Build.cs` を見て、モジュール構成と依存関係を確認する。
2. **設計**: C++ で書く部分と Blueprint に任せる部分を分けて、ユーザーに伝える。
3. **実装**: `unreal-specialist` の方針に沿って `.h` / `.cpp` を書く。
   - 新しいモジュールを使う場合は `*.Build.cs` の依存に追加する。
   - `GENERATED_BODY()` と `*.generated.h` の include（最後に書く）を忘れない。
4. **ビルド**: ヘッダーを変えたらエディタを閉じてビルドするよう伝える（Live Coding はヘッダー変更に弱い）。
5. **エディタでの作業を伝える**: Blueprint の作り方、詳細パネルで設定する値などを手順として書く。
6. **レビュー**: `code-reviewer` で変更を確認する。
