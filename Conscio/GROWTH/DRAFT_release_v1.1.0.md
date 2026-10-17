# 📦 Release v1.1.0 ドラフト (⚠️ 要承認 — 投稿前に必ず確認してください)

> 対応ステータス: **未公開** (あなたのOK待ち)
> RULES.md第3条により、公開前に必ず確認いただきます。
> AI使用表記を含みます (第3条)。

---

## リリースノート本文 (ドラフト)

**Conscio v1.1.0 — オンデバイスAI提案エンジン搭載**

「本齣をここに置く」かんがえとを、AIが背中から助けます。

新機能:
- 🤖 **オンデバイスAI文脈認識** (Apple NaturalLanguage framework採用)
  - あなたの作業画面から重要なキーワードを抽出します
  - 生成情報はMacの外に出ません (完全オンデバイス)
- 🔎 **AIコンテキスト検索サジェスト**
  - 文脈キーワードから「今欲しい検索」を自動提案
  - 例:「SwiftUI上の実装中に"SwiftUI syntax"提案」
- 🧩 その他改善

⚠️ 本リリースは **AIを利用して開発・ドラフト作成**されています (AI非認証/人間確認付き)。

## 変更内容 (開発者見)
- `ContextMonitor.swift`: NLTaggerによる品詞タグ付けで名詞/動詞抽出
- `MainViewModel.swift`: キーワードからDuckDuckGo検索サジェスト生成
- `Package.swift`: tools/GROWTH/landingをコンパイル対象から除外
- Info.plist: v1.1.0 (プロダクトバージョン = 2)

## 承認後にやること (OKをいただいたら)
1. `gh release create v1.1.0 <zip> --notes <draft>` (zip作成済み)
2. ランディングページのバージョン表記をv1.1.0に更新+ push (AI表記付き3行変更)
3. READMEにAI機能を追記+ push
4. リモートに蓄積したローカルコミットをpush
