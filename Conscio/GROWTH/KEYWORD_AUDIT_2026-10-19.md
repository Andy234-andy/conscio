# キーワード抽出監査 (進化#44) — 2026-10-19 18:03 実施

> 架空のサンプルタイトルのみ使用・個人情報なし。ContextMonitor の抽出ロジック mirror で検証。
> 監査の過程で発見した不具合と対応:
> 1. 日本語は NLTagger(lexicalClass) で全語 OtherWord 判定 → NLP経路は実質不発、丸ごと1キーワード化 (実測)
> 2. 対策: フォールバックに語分割精製 (#44) — 助詞・ひらがなのみの語を除去 → 改善版の実測は下表のとおり

| 窓タイトル (架空) | 検出言語 | 抽出キーワード |
|---|---|---|
| 無題 | NLLanguage(_rawValue: zh-Hant) | <_filtered> |
| loading… | NLLanguage(_rawValue: en) | <_filtered> |
| untitled | NLLanguage(_rawValue: en) | <_filtered> |
| 進化ログを見る | NLLanguage(_rawValue: ja) | 進化 / ログ / 見る |
| 集中の高め方 — Qiita | NLLanguage(_rawValue: ja) | 集中 / 高め / Qiita |
| アルゴリズム入門 | NLLanguage(_rawValue: ja) | アルゴリズム / 入門 |
| 数学の問題集 | NLLanguage(_rawValue: ja) | 数学 / 問題 |
| Evolution#43 — README.md | NLLanguage(_rawValue: en) | Evolution / README.md |
| Stack Overflow - Where Developers Learn | NLLanguage(_rawValue: en) | Stack / Overflow / Developers / Learn |
| How It Works - conscio Wiki | NLLanguage(_rawValue: en) | Works / conscio / Wiki |
| 2026年度まとめ_第2稿 | NLLanguage(_rawValue: ja) | 2026 / 年度 |

