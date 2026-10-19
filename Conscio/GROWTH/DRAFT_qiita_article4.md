# SwiftのNLTaggerで日本語をまともに解析する3つの工夫 — 短文「窓タイトル」を2秒毎に読むための設計と実測

> ✅ **公開済（2026-10-19 19:4x・ユーザー承認）**: https://qiita.com/Atsuki33/items/22a016208cab808bba1a

> **本記事はAIアシストで執筆し、人間が内容を確認しています。**
> 例はすべて個人開発アプリ**Conscio**（macOS常駐・オフラインNLP）の実装に基づく実測です。

Conscioは、最前面アプリの**窓タイトル**を2秒ごとに読み、そこからキーワードを抽出して提案や文脈表示に使います。条件は3つ:

- **弱い入力**: 「無題」「loading…」「イマイチ意味のない文字列」のような散漫な文字列
- **短い処理**: 2秒ループ内で終わる軽量処理（バッテリーのため）
- **強い制約**: 外部API・送信ゼロ（データ外送禁止）

この3条件で動くNLPをどう組むか — 工夫3つと、「設計の仮定が崩れていた」を監査で発見した実話を書きます。

## 工夫1: 言語を「検知」して「明示」する

NLTagger は言語未指定だと自動判定します。2〜3語の短文では判定がブレるため、`NLLanguageRecognizer` の結果を**明示的に**渡します。取得できなかった(nil)ときは無理に設定せず自動判定に任せます:

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

## 実測: 日本語では品詞タグが効果を発揮しません（ここが今日の本題）

「名詞だけ重みを高くする」という一般的な設計を入れていたのですが、**監査ツールでの実測で、日本語ではこの仮定が崩れている**ことが分かりました。

NLTaggerの`lexicalClass`スキームで日本語窓タイトルを解析すると、**すべての語が `OtherWord` になります**。品詞情報が得られないので `noun`/`verb` のフィルタは一度も真になりません:

```
入力: 集中の高め方
結果: OtherWord='集中' OtherWord='の' OtherWord='高め' OtherWord='方'
```

（この挙動は macOS 標準の言語処理の粒度の問題で、言語を明示しても変わりません。上の1行検証コードで誰でも再現できます。）

この影響は連鎖的でした:

1. 日本語のタイトルではNLP経路が実質不発
2. キーワード抽出が**全面的にフォールバック経路**（区切り文字での単純分割）で動いていた
3. 区切り文字のない日本語チャンクは**丸ごと1語**になる — 「進化ログを見る」がそのまま1キーワードとして提案に出ていた

## 対策: フォールバックを「まともな日本語処理」にする

NLP本体の代わりに、フォールバック側を語単位の精製にしました。

- チャンクごとに `NLTokenizer` で**再トークン化**
- 助詞（の/を/に/は/が/で/…）の**除外**
- **ひらがなのみの語**の除外（助詞・動詞のかたまり粒子が拾われない）
- 閾値は言語別（日本語2文字以上・欧米3文字以上）

```swift
tokenizer.enumerateTokens(in: chunk.startIndex..<chunk.endIndex) { range, _ in
    let w = String(chunk[range])
    let hiraganaOnly = !w.isEmpty && w.unicodeScalars.allSatisfy { (0x3040...0x309F).contains($0.value) }
    if w.count >= fbMinLen, !particles.contains(w), !hiraganaOnly {
        collected.append(w)
    }
    return true
}
```

実測（架空サンプル・11件の監査報告から抜粋）:

| 窓タイトル (架空) | 旧 (丸呑み) | 新 (精製後) |
|---|---|---|
| 進化ログを見る | 進化ログを見る | 進化 / ログ |
| 集中の高め方 — Qiita | 集中の高め方 / Qiita | 集中 / 高め / Qiita |
| 数学の問題集 | 数学の問題集 | 数学 / 問題 |

（正確に記すと精製後も「見る」のように動詞らしき語が残ることはあります。品詞が取れない以上、消しすぎより拾いすぎ、という方針です。）

## 工夫3: 解析する前につまみ出す

解析コスト最大の節約は、**解析しないという選択**です。無意味なタイトルをNLPに渡す前に除外します:

```swift
let meaningless = trimmed.isEmpty
    || lower == "untitled"
    || lower == "無題"
    || trimmed == appName           // タイトルがアプリ名そのまま
    || lower == "page 1"
    || lower.hasPrefix("loading")
```

loading類や「無題」を解析から外すだけで、ノイズのキーワードが提案に現れなくなりました。**強いフィルタは、NLPの前に置くもの**です。

## 監査ツールの運用

これらの検証は `tools/keyword_audit.swift`（開発用ツール）で行いました。架空のサンプル11件を入力に、現在の抽出ロジック mirror を走査し、表形式の実測結果を出します。**個人情報は含みません**（タイトルはすべてダミー）。設計の仮定を定期的に数値で検証するのが、この監査の目的です。

## 代替案との比較で意識したこと

| 軸 | NLTagger（オフライン） | 外部LLM API |
|----|----------|-------------|
| 速度 | ミリ秒台 (2秒ループ余裕) | ネット待ち・リトライ |
| 費用 | 0円 | 従量課金 |
| プライバシー | 端末内完結 | 送信が必ず発生する |
| 精度 | 品詞タグは日本語で効かない | 高精度 |

**結論**: 「外にデータを流さない」条件を守るため、日本語での品詞の弱さは**フォールバック側の精製で補う**構成にしました。誤キーワードが出ても、提案は利用者が一目で捨てられる軽さの表示なので、失敗のダメージが小さいという判断です。

## まとめ

- 言語は検知して明示（nilは自動に任せる）
- **NLTaggerの品詞タグは日本語で効かない**（すべてOtherWord） — 少なくともmacOS現行では
- 効かない経路に依存するより、フォールバックを「まともな語分割+精製」にする
- 設計の仮定は監査ツールで定期的に数値実測する（仮定が崩れていたら設計を直す）

- コード: https://github.com/Andy234-andy/conscio （`Conscio/Services/ContextMonitor.swift`・`Conscio/tools/keyword_audit.swift`）
- 安全設計: https://github.com/Andy234-andy/conscio/blob/main/Conscio/SECURITY.md
- 以前の連載: [第1](https://qiita.com/Atsuki33/items/9f1b6af7a9edc5b70968)・[第2](https://qiita.com/Atsuki33/items/041923a512b1c7b3328b)・[第3](https://qiita.com/Atsuki33/items/dbd23baa4b3976dfdfae)

---

*本記事はAIアシストで執筆し、人間が内容を確認しています。*
