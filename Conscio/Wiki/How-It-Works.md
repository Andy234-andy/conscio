# 仕組み (How It Works)

Conscioは**完全オフライン**で動作します。ここでは怜俐がどうなっているかを見せます。

## アーキテクチャ概曆

```
ContextMonitor (2秒vue)
 ├─ Accessibility API (AXUIElement)
 │   → 最前面アプリ名・ウィンドウタイトル・ドキュメントパス
 ├─ NLLanguageRecognizer → NLTagger.lexicalClass
 │   → 文脈から{名詞/動詞}のキーワードを抽出（オフデバイス）
 ├─ AppleScript (Safari / Chrome)
 │   → 最前面タブのURL (6秒ごとにGet)
 └─ Context Model → MainViewModel

NotificationManager
 └─ UNUserNotificationCenter delegate
     → 集中中の通知を [] (表示しない) で捹消し、件数だけ数える
     → 解除時: サマリー通知を1件だけ出す

HabitTracker
 ├─ コンテキスト変化ごとに apps/duration を刻む
 └─ Application Support JSON に永続化 (再起動OK)
```

## 2つの権限をなぜ使うのか

| 技術 | 理由 | 取れるもの |
|------|------|-----------|
| **Accessibility API** | macOSで「他アプリのUI要素」を合法的に読む唯一の正攻法 | アプリ名・ウィンドウタイトル・ドキュメント名 |
| **AppleScript(Safari/Chrome)** | ブラウザは AppleScript 辞書でURLを公開している、一番確実な方法 | 最前面タブのURL |

どちらも**読み取りのみ**で、あなたのファイル・キー入力・スクリーンには一切触れません。

## オンデバイスAI (NLTagger)

アップル提供の NaturalLanguage framework は端末内で完結するタグ付けを供給します。
Conscioはこれを **文脈→キーワード→検索提案** の要件解析に限り使用しています（1件もネットワークに触れません）。

## データの保存場所

```
~/Library/Application Support/Conscio/habitstats.json
```

- 集中秒数/切替回数/アプリ別秒数/日次データ—以上だけ
- **削除すれば統計リセット**、クラウドではなくご自身のMac上のみ
- 遠隔送信・分析送信・telemetry: **ゼロ**

---

*本Wikiの記事はAIアシストで執筆し、人間が内容を確認しています。*

## 進化で増えた要素 (v1.3.0時点)

- **直近アプリ履歴バッファ**: 直近10アプリを新着順で保持・JSON永続化 → 「戻る提案」の材料。クリックで**実際にアプリ切替**（NSWorkspace activate/未起動ならlaunch）
- **集中達成スコア**: `min(100, 今日の集中秒 ÷ 3600 × 100)` — 目標60分/日の**実データ計算のみ**。デモ値・仮値はコード上にも存在しない
- **フェイクコンテンツ撤去ポリシー**: 提案欄に出るのは実在するアプリ・実キーワード検索だけ（デモ文書/example.comは進化#17で全面削除）
- **L10n一元管理**: 通知文面・時間フォーマット・チャートラベル・アクセシビリティ説明まで全てLocalizer経由（ja/en自動切替）
