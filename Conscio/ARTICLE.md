# 「あの資料どこ...」が消えた世界。文脈認識Macアプリ「Conscio」を1人で作って公開するまで

## きっかけ：Macの前に生活があった

Macって、最高の道具です。でも僕らの1日は、たぶんこんな感じでした。

- エディタが開いている。途中で「あの資料どこに置いたっけ…」
- Safariで検索。別のタブで符号が消える。
- チャットが鳴る。気づいたら15分損失している。

つまり「情報が多い」時代は終わり、「**文脈が乱れる**」時代が本題でした。
ここから、Conscioを作ろうと決めました。

## 設計思想：選ばせるのではなく、選ばれるべき情報だけを置く

主要3機能はこうです：

1. **🧠 リアルタイム文脈認識** - 2秒ごとに最前面アプリ・ドキュメントを監視 (Accessibility API + NSWorkspace)
2. **💡 スマート提案** - 文脈上のキーワードから関連資料・タスクを提示してくれる(UIはSwiftUI製メニューバーポップオーバー)
3. **🛡️ インテリジェントノイズ抑制** - 集中中は通知を完全に静かにして、解除したタイミングでサマリーだけ届ける
4. **📈 デジタル習慣レポート** - 集中時間と文脈切替を数値化し、ポジティブに褒める(UI設計)

**一つだけ、世界で最初にしたこと。**
「通知を殺す」のではなく、**「静かにする」**。これがConscioの思想です。

## 実装の裏話（敗北の記録）

### 戦場 1: AXUIElement の Optional と格闘
macOSの Accessibility API はC言語層なので、SwiftのOptionalと相性が超悪い。
`AXUIElementCopyAttributeValue` で戻り値への `AnyObject?` を正しく提わざるを得ず、
初着手時には`takeUnretainedValue()`がOptional条件エラーで落とされました。
最終的に修復: `if let windowElement = focusedWindow` + 安全なキャスト。

### 戦場 2: バンドル外実行で静かに死ぬ
Swift Package Managerでビルドしたバイナリを直接実行すると、
`UNUserNotificationCenter` が暗黙 crash（バンドルIDがなくても動かず、macOSは黙って死なせる）。
画面には**何も出ない**。Consoleも完全に無音。
⇒ 解決策は「**正規アプリバンドル (.app) を手作りして**」使うこと:
Info.plist を手書き → binary コピペアイコンリスロ動作 → ad-hoc codesign。

ここで学んだこと: **「Macアプリ開発に .xcodeproj は不要。ただの Info.plist と正しい配置で十分動く」**

### 戦場 3: 「256専用ではない」アイコン(iconset 製作)
SwiftScriptから AppKit の NSImage を使用し、プログラム的アイコンを作った。
gradient デザイン → iconutil → icns → Info.plist への CFBundleIconFile 追加。
端的に、**emojiは強い**。1行で🍎風の丸角矩形あり UI を破壊的に再現できる。

## 注意：世の中への公開は“ iCloud と一番苦労した”部分

GitHubコマンドライン (gh) からpushしようとしたら、 **GitHubはパスワード方式を廃止済み** ということに。
2026年における代金：**トークン or OAuth流れ**。
実戦においては Homebrew→gh CLI→ `gh auth login` でワンタイムコードをブラウザで認証する流れに。
開発者アカウント不要で、 **15分でGitHub Pages ホスティングまで完遂** しました。

## さあ、Conscioが目指すもの

**全員が、Macに常駐する、世界一優しい相棒を手に入れること。**

現状は v1.0 です。公開した世界観：

- **GitHub** : https://github.com/Andy234-andy/conscio
- **公式サイト** : https://andy234-andy.github.io/conscio/
- **ダウンロード v1.0.0** : https://github.com/Andy234-andy/conscio/releases/latest

**できる限りのフィードバックを欲しいです。** Issueで意見を叩きつける、スター☆を押す、この記事に「使りました」コメント、全部歓迎です。

## 次はこう進化させるつもりです

1. **本物のAI提案** (オンデバイス LLM 連携)
2. **多言語対応** (英語・中国語・スペイン語)
3. **macOS集中モードフィルター統合** (OS-native)
4. そして、 **この経験をソフトウェア1人でしかできない形にして世に格化する** 本公開...

最後まで読んでくれる読者のおかげです。どう地元の桃葉のご著明です、ありがとう。
