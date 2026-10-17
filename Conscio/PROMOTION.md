# 📢 Conscio 宣伝素材・ローンチキット

## 1. SNS投稿文言

### X (Twitter) 初回告知ツイート

```
🧠 Conscio — あなたの集中を、Macが守る。

資料を探す時間、通知で断たれる集中。全部なくせる。

メニューバー常駐のMacアプリ「Conscio」を公開しました。
開いている画面の「文脈」を読み、必要な情報だけを差し出します。

#Conscio #Macアプリ #生産性 #デジタルウェルビーイング
```

### X 使用シーン投稿

```
「あの資料、どこに置いたっけ…」

この悩み、Conscioが解決します。

🧩 今見ている画面の文脈から自動で関連資料を提示
🛡️ 集中モード中は通知を自動抑制
📈 集中習慣を可視化して伸ばす

Macで仕事のスピードが変わる、体験を。
```

### スローガン

> **「選ばせるんじゃない。選ばれるべき情報だけを、そこに置く。」**

---

## 2. 記事タイトル案 (Qiita / Zenn / note)

1. Macの文章を書きながら資料を探していた私を救った、文脈認識アプリ「Conscio」をSwiftで作った話
2. 「通知を消す」のではなく「静かにする」— 集中を守るMacアプリの設計思想
3. 1人でMacアプリをゼロから作って公開するまで（SwiftUI・メニューバー常駐）

---

## 3. スクリーンショット撮影ガイド（あなたにお願いする1箇所）

- メニューバーの🧠をクリックしたポップオーバーのスクショ（最も信憑性が出る！）
- その後、**Cmd+Shift+5 → 選択範囲録画**で、アプリを切り替えながらポップオーバーの中身が変わる様子を10-15秒録画 → GIF変換
- Campaignに使う現物だけ撮ってくだされば、あとの編集案は全部こちらで

---

## 4. GitHub公開手順（あなたのアカウントでやる5ステップ）

1. github.com で New repository → 名前 `conscio` ・ Public
2. ターミナルで:
```bash
cd "/Users/atsuki/Documents/Default Project"
git init && git add Conscio Conscio.app Package.swift
git commit -m "Conscio v1.0 公開"
git branch -M main
git remote add origin https://github.com/<あなたのID>/conscio.git
git push -u origin main
```

3. リポジトリの About 欄に：「🧠 Context-aware menu bar navigator for Mac」を入れる

---

## 5. ランディングページ公開方法

`Conscio/landing/index.html` 単体がページそのものです。

- **GitHub Pages (無料・最速)**: 上記リポジトリ内 `docs/` に index.html を置き、Settings → Pages で Publish。URLは `https://<ID>.github.io/conscio/`
- **Netlify**: https://app.netlify.com/drop に index.html をドラッグするだけで即公開（配信URLがもらえる）

---

## 6. ローンチ当日の公開順

1. X投稿（初回告知）＋ リポジトリURL
2. Qiita記事公開（長文物語）
3. その記事をnoteにも再掲（言い方を「技術」→「体験」に変える）
4. Macまとめ系メディアへのPitch（メール/お問い合わせフォーム）

---

## 📍 やってもらうこと・やらなくていいこと

- **必須のお願い**: スクショ撮影 / GitHub push（要あなたのアカウント）
- **やっておきます**: 素材・文面・コード整備・アイコン・動作検証
	※ ソーシャルアカウントそのものへの「自動投稿」はアカウント認証が必要なため、あなたのクリック1回で済む状態まで作っておきます。
