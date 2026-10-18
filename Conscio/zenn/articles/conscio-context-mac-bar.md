---
title: 「あの資料どこ…」が消えた世界。文脈認識Macアプリ「Conscio」を1人で作って公開するまで
emoji: "🧠"
type: "tech"
topics: ["mac","swift","swiftui","個人開発","AI"]
published: true
---

**※この記事はAIアシストで執筆し、人間が内容を確認して公開しています。**

## きっかけ：Macの前に生活があった

Macって、最高の道具です。でも僕らの1日は、たぶんこんな感じでした。

- エディタが開いている。途中で「あの資料どこに置いたっけ…」
- Safariで検索。別のタブで集中が消える。
- チャットが鳴る。気づいたら15分損失している。

つまり「情報が多い」時代は終わり、「**文脈が乱れる**」時代の本題って案。
ここから、Conscioを作ろうと決めました。

## 設計思想：選ばせるのではなく、選ばれるべき情報だけを置く

主要4機能はこうです：

1. **🧠 リアルタイム文脈認識** - 2秒毎に最前面アプリ・ドキュメントを監視 (Accessibility API + NSWorkspace)
2. **🤖 オンデバイスAI キーワード抽出** - Apple NaturalLanguage framework が文脈から重要単語を抽出 (v1.1新機能)
3. **🛡️ インテリジェントノイズ抑制** - 集中中は通知を完全に静かに。解除したタイミングでサマリーだけ届ける
4. **📈 デジタル習慣レポート** - 集中時間と文脈切替を数値化し、ポジティブに褒める

**他と違う一つ目玉**が「通知を殺す」のではなく、**「静かにする」**。これがConscioの思想です。

## 実装の裏話（敗北の記録）

### 戦場 1: AXUIElement の Optional と格闘
macOSの Accessibility API はC言語層なので、SwiftのOptionalと相性が超悪い。
`AXUIElementCopyAttributeValue` で戻り値への `AnyObject?` を正しく建ち上げざるを得ず、
初着手だと `takeUnretainedValue()` は Optional条件エラーで落とされました。

### 戦場 2: バンドル外実行で静かに死ぬ
Swift Package Managerでビルドしたバイナリを直接実行すると、
`UNUserNotificationCenter` が暗黙 crash（バンドルIDがなくても動かず、macOSは黙って死なせる）。
画面には**何も出ない**。Consoleも完全に無音。
⇒ 解決策：**正規アプリバンドル (.app) を手作り**で実装入れ Info.plist を手書き → binary コピペ → ad-hoc codesign → アイコンは emoji できる Node? (AppKit script) → iconutil 製 icns。

ここで学んだこと: **「Macアプリ開発に .xcodeproj は不要。ただの Info.plist と正しい配置で十分動く」**

### 戦場 3: ストレージが全世界下限にして TRILLION 張り付く
build途中にディスク100%になったことで、whatever マイナーな I/O エラー (code:60) の世界で何時間静止。
**安全なキャッシュのみ**の掃除で (Xcode DerivedData / brew / pip / etc.) 完全復活。CIのある存在では、"実チャン 元に戻す" 押せないだけ。
(何も同じエラーを(CI)の個々ではないことを)

## 公開のその先：GitHub × Apple CLI × GitHub Pages

`gh auth login` からワンタイムコード認証 → push → **GitHub Pagesに15分でホスティング**まで。
全員がこれが「世界」に届いていると悟るところが一番感動的でした。

## Conscioが目指すもの

**全員が、Macに常駐する、世界一優しい相棒を手に入れること。**

現状は v1.1.0 (オンモファイルAI込み)です：

- **GitHub** : https://github.com/Andy234-andy/conscio
- **公式サイト** : https://andy234-andy.github.io/conscio/
- **Download v1.1.0** : https://github.com/Andy234-andy/conscio/releases/latest

Issueで叩きつける、☆スター☆、コメント —**全部歓迎。** よろしくお願いします 🙏
