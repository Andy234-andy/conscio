# SwiftのNLTaggerで日本語をまともに解析する3つの工夫 — 短文「窓タイトル」を2秒毎に読まないための設計

> **本記事はAIアシストで執筆し、人間が内容を確認しています。**
> 語る例はすべて個人開発アプリ**Conscio**（macOSメニューバー常駐・オフラインNLP）の実装に基づく実測です。

Conscioは、最前面アプリの**窓タイトル**を2秒ごとに読み、そこからキーワードを抽出して提案や文脈表示に使います。条件は3つ:
- **弱い入力**: 「登録済みの資料志向サイト?...」ではなく「spinoff.md 進化#, 無題, loading…」のような散漫な文字列
- **短い処理**: 2秒ループ内で終わる軽量処理（バッテリーのため）
- **強い制約**: 外部API・送信ゼロ（データ外送禁止)

この4条件で動くNLPをどう組むか — 3つの工夫と、どちらの限界かを書きます。

## 工夫1: 言語を「検知」しない、明示する

NLTagger は言語未指定だと自動判定しますが、**2〜3語の短文では判定がブレます**（英単語1個だけの諸々のタイトル、日本語2文字だけの諸々）。

```swift
let recognizer = NLLanguageRecognizer()
recognizer.processString(nlpText)
let detected = recognizer.dominantLanguage
let tagger = NLTagger(tagSchemes: [.lexicalClass])
tagger.string = nlpText
if let lang = detected {
    tagger.setLanguage(lang, range: nlpText.startIndex..<nlpText.endIndex)
}
```

ポイントは **detected が nil でも NLTagger に任せるのを敢えてやめて**、取得できた言語だけ**明示**するところです。おかしな言語を設定するより、未設定（自動判定に任せる）の方が結果は安定しました。

## 工夫2: 品詞フィルタの「長さ基準」を言語ごとに分ける

品詞は `lexicalClass` の `noun`（名詞）・`verb`（動詞）だけ拾います。ところがこのままだと、日本語特有の「1文字の粒」が拾われます。実測に基づく閾値:

```swift
if tag == .noun || tag == .verb {
    let word = String(nlpText[range])
    let minLen = isJapanese ? 2 : 3   // 日本語は2文字, 欧米は3文字以上
    if word.count >= minLen { aiKeywords.append(word) }
}
```

日本語は**2文字で意味を持つ名詞が多い**（進化・集中・戦略など）一方、英語で2文字だと不恰好な頭字ばかりです。**この1行で精度が大きく変わります**。

## 工夫3: 解析する前につまみ出す

解析コスト最大の節約は、**解析しないという選択**です。無意味なタイトルをNLPに渡す前に除外します:

```swift
let meaningless = trimmed.isEmpty
    || lower == "untitled"
    || lower == "無題"
    || trimmed == appName           // タイトルがアプリ名そのまま
    || lower == "page 1"
    || lower == "loading…"
if meaningless { activeDocument = nil }
```

loading類や「無題」を解析から外すだけで、**ノイズのキーワードが提案に現れなくなりました**。NLPに強いフィルタは、NLPの前に置くものです。

## 代替案との比較で意識したこと

Conscioは上記のようなApple純正（NLTagger）**オンデバイスの軽量NLP**を軸にしています。外部の大型モデルを絡めた対案と比べて:

| 軸 | NLTagger | 外部LLM API |
|----|----------|-------------|
| 速度 | ミリ秒台 (2秒ループ余裕) | ネット待ち・リトライ |
| 費用 | 0円 | 従量課金（接続不足で信頼性低下） |
| プライバシー | 端末内完結 | 送信が必ず発生する |
| 精度 | 誤タグがある（要注意） | 高精度 |

**結論**: 提案の精緻さを追うならLLMですが、**「外にデータを流さない」条件を守るならNLTaggerしかない** — 誤タグの寄与は、工夫2の閾値でかなり緩和できました。

## 落とし穴と現実

- **magazineArticle動詞**: 「進化する」の「進化」が「する」に混在する可能性 → 動詞掃取は用途が少なければ疑似。
- **numeeと敬称**: 「たぶん長い。」と「至る所の。」…
- **フォールバック**: NLPが空のときは区切り文字の単純分割に落とす設計にしています（文書タイトルはファイル名が多いので悪くない場合が多い）。

## まとめ

- 言語は検知・明示で打つ（nilは自動に任せる）
- 閾値は言語別（日本語2字/正輸3字）
- NLPの前にフィルタ（無価値タイトルを踏まない）
- 外に流さないという条件があれば、NLTaggerは実用域に達します

- 投稿コード: https://github.com/Andy234-andy/conscio （`Conscio/Services/ContextMonitor.swift`）
- 仕組み解説Wiki: https://github.com/Andy234-andy/conscio/blob/main/Conscio/Wiki/How-It-Works.md
- 安全設計: https://github.com/Andy234-andy/conscio/blob/main/Conscio/SECURITY.md
- 以前の記事: [第1](https://qiita.com/Atsuki33/items/9f1b6af7a9edc5b70968)・[第2](https://qiita.com/Atsuki33/items/041923a512b1c7b3328b)・[第3](https://qiita.com/Atsuki33/items/dbd23baa4b3976dfdfae)

---

*本記事はAIアシストで執筆し、人間が内容を確認しています。*
