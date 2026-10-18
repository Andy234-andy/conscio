# DRAFT Qiita記事 (トークン受領後に投稿 / 投稿前にユーザー確認済みにすること)

## 投稿タイトル
Swiftで文脈を認識するメニューバーアプリ「Conscio」を作った話 — Xcodeプロジェクトなし・オフライン・オンデバイスAI

## タグ
macOS, Swift, SwiftUI, 個人開発

## 本文 (↓ここからまるごとbodyに入れる)

---

**※本記事はAIアシストで執筆し、内容を人間が確認して公開しています。またこのプロジェクト本来のライセンスはMIT、無料で利用できます。**

Macで作業していると、こんな瞬間がありませんか。

- エディタを開いたまま「そういえばあの資料どこだっけ…」
- 検索のためにブラウザを開く → 別のタブに吸われて集中が切れる
- 通知が鳴って、戻ってきたときには10分が消えている

この「文脈が切れる」時間を少しでも減らしたくて、**Conscio（コンシオ）**というmacOSのメニューバーアプリを作って公開しました。

https://github.com/Andy234-andy/conscio

## Conscioの機能

1. **リアルタイム文脈認識** — 2秒ごとに最前面アプリと開いているドキュメントを検知（Accessibility API + NSWorkspace）
2. **オンデバイスAIキーワード抽出** — Apple NaturalLanguage frameworkが、作業中の文脈から重要語を取り出して「いま欲しい検索」を提案。**処理はすべて端末内であり、外部送信はありません**
3. **インテリジェント通知抑制** — 集中モードのアプリを検知している間は通知を静かにし、解除したときに「抑制した件数」をまとめて1件だけ通知
4. **デジタル習慣レポート** — 累積の集中時間・文脈切替回数・アプリ別利用時間を可視化。直近7日の集中時間をSwift Chartsの棒グラフで表示

開発期間はここまで数日、全コードはGitHubで公開中です（MIT）。

## 実装で得た学び

### 1. Xcodeプロジェクト（.xcodeproj）は実は不要だった

Swift Package Managerで`swift build`した実行ファイルは、そのままでは通知などが動かず起動も不安定です。原因は**バンドルがないこと**。そこで`Info.plist`を手書きした正規の`.app`バンドルをディレクトリ構造だけで自作しました。

```
Conscio.app/
├── Contents/
│   ├── Info.plist          ← 手書き（LSUIElement=true で Dock 非表示）
│   ├── MacOS/Conscio       ← swift build の成果物をコピー
│   └── Resources/*.icns    ← iconutil で生成
```

`codesign --deep --sign -`のアドホック署名をすれば取り急ぎローカル配布も可能です。**「Macアプリ開発はXcodeで開くもの」という固定観念が崩れたのが一番の収穫でした。**

### 2. AXUIElement（Accessibility API）との付き合い方

`AXUIElementCopyAttributeValue`はCベースのAPIで、戻り値の扱いに癖があります。Optionalの二重ネストやAnyObjectのキャストを丁寧にほどく必要があり、ここがSwiftで最も「C言語に触れている」感覚でした。権限は`AXIsProcessTrustedWithOptions`でプロンプトを出せます。

### 3. NLTaggerの日本語精度は「言語を明示する」だけで改善する

v1.1で入れたオンデバイスNLPは散発的に再現する改良です。

```swift
let recognizer = NLLanguageRecognizer()
recognizer.processString(text)
let tagger = NLTagger(tagSchemes: [.lexicalClass])
tagger.string = text
if let lang = recognizer.dominantLanguage {
    tagger.setLanguage(lang, range: text.startIndex..<text.endIndex)
}
```

言語を明示的に設定しないと、URLフラグメントのような短文では品詞タグ付けが不安定になります。日本語は2文字の名詞でも意味を持つので、キーワードの最小文字数を言語ごとに分けています。

### 4. ブラウザのURLはAppleScriptが一番早い

Accessibilityだけでもtitle属性は取れるのですが、URL取得はSafari/ChromeがAppleScriptを公開しているのでそちらが確実です。

```applescript
tell application "Safari" to get URL of front document
```

初回のみmacOSから「Conscio が Safari を制御しようとしています」のconfirmシートが出ます。まだ一度もユーザーの操作を経ないAPIではない点に注意します。

## 進化の足跡

公開後1日でこのありました:

- v1.0.0 — 初公開（文脈認識/スマート提案/通知抑制/習慣レポート）
- v1.1.0 — オンデバイスNLP＋AI検索サジェスト
- その後 — 習慣データのJSON永続化、日本語NLP改良、集中モードの視覚化（メニューアイコンが紫色に）、ブラウザURL実取得、7日間集中チャート

## よかったら使ってみてください

- GitHub: https://github.com/Andy234-andy/conscio
- ダウンロード: https://github.com/Andy234-andy/conscio/releases/latest
- 公式サイト: https://andy234-andy.github.io/conscio/

要件はmacOS 13+ / Apple Siliconです。未署名ビルドのため初回起動は右クリック→「開く」をお願iseます。改善案・バグはIssueでぜひ教えてください🙏
