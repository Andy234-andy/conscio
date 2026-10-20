*本記事はAIアシストで執筆し、人間が内容を確認しています。実測値のみを記載し、推測は明示します。*

## 小さな機能に一貫した設計原則を埋める

前回の記事（不在時の省CPU）から、私はメニューバー常駐アプリ「Conscio」の機能を今日この日だけで3本（30日チャート・提案の却下・CSV書き出し）追加しました。個々は小さい改造ですが、意識したのは「**ユーザーに躓いた道を残さない設計**」という一つの縦糸でした。この記事はその3本を混ぜて書きます。

## 1. 目標は「変えられる」ものにする (30日チャート + 目標破線)

レポートに直近30日の集中時間チャートを追加しました。Swift Chartsの AreaMark（面）+ LineMark（線）を catmullRom 補間で重ねていますが、重要なのはグラフの上に引いた**緑の破線**です。

```swift
RuleMark(y: .value("goal", Double(HabitTracker.dailyGoalSeconds / 60)))
    .foregroundStyle(.green.opacity(0.55))
    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
    .annotation(position: .top, alignment: .trailing) {
        Text(L10n.target(Int(HabitTracker.dailyGoalSeconds / 60)))
            .font(.caption2)
    }
```

この破線は **設定のStepper値（15〜240分・既定60）を毎回読みにいく** ので、ユーザーが目標を90分に変えると、レポートのスコア・色・この破線の位置と「目標 90分/日」の表記が**全部同時に動く**。データ構造は既存の `dailyFocusMap [String: 秒]` そのまま（新規の保存形式ゼロ）で実現しています。「グラフさえあれば達成感がわかる」より「**自分で決めた線に対してどうだったか**」の方が長く使えると考えています。

## 2. うっかりは「日の境界」で許される (提案の却下)

検索提案に ✕ マークを付けました。押すと今日は二度と出なくなりますが、**翌日は自動で再登場**します。却下の保存は UserDefaults に「語→日付」というペアで頻繁な JSON を書かない小さな保存です。

```swift
func dismissKeywordSuggestion(_ keyword: String) {
    var dict = dismissedKeywords.filter { $0.value == today } // 期限切れを一掃
    dict[keyword] = today
    UserDefaults.standard.set(dict, forKey: "dismissedKeywordSuggestions")
    suggestions.removeAll { $0.keyword == keyword } // 即時非表示
}
```

設計判断は「**誤爆に寛容であること**」。ひとたび完全に消すと、ユーザーは「本物の提案も失う恐怖」から ✕ を押さなくなり、機能が死にます。期限を「同じ日」に限定しただけで、押すハードルが大きく下がりました。

## 3. 書き出し先は「ユーザーが決める」 (CSV)

レポートに「直近30日をCSVで書き出す」ボタンを追加しました。NSSavePanel を使うのは、**アプリが Documents 等に勝手に書くのを避けるため**です。

```swift
let panel = NSSavePanel()
panel.nameFieldStringValue = "conscio-focus-30days.csv"
panel.allowedContentTypes = [UTType.commaSeparatedText]
panel.begin { response in
    guard response == .OK, let url = panel.url else { return }
    try habitTracker.last30DaysCSV().write(to: url, atomically: true, encoding: .utf8)
}
```

CSVは `date,focus_minutes` の30行だけです。小さいデータには小さい権限で十分です。

## 実装のつまずきメモ

- CSV関数をHabitTrackerに差し込むとき、コメントの関連付けが一時的にずれました（古いコメントが別プロパティに付いていた）→ **read検証で捕捉して即修正**。「表示okを見て信じない」習慣が効いた瞬間でした。
- Views系ファイルを触るビルドは 206〜257秒（当日実測・ログ記録済み）。依存が広い再コンパイルが起きるため、連続UI変更の日は1回のビルドに複数の変更を乗せる方が合理的です。

## 本日の数字（誇張なしで）

- 今日の機能投入: 4本（目標Stepper / 不在時省CPU / 30日チャート+目標破線 / 提案却下+CSV）
- v1.4.3リリース: DL 0件（公開90分時点・正直に記録）
- 記事6本のPV合計: 約1,840

宣伝ゼロでも数字は動くもので、継続が唯一の戦略です。

リポジトリ: https://github.com/Andy234-andy/conscio （マルウェア駆除の監査記事など、実装のメモを公開しています）
