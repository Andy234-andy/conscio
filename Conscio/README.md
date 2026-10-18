# Conscio 🧠

<p align="center">
  <img src="landing/og-card.png" alt="Conscio" width="720">
</p>

**「情報は選ばせるものじゃない。選ばれるべき情報だけが、そこにあればいい。」**
*本プロジェクトはAIアシストで設計・実装され、人間が確認・意思決定しています。*

<p align="center">
  <a href="https://github.com/Andy234-andy/conscio/releases/latest"><img alt="Downloads" src="https://img.shields.io/github/downloads-pre/Andy234-andy/conscio/latest/total?label=downloads&color=blue"></a>
  <a href="https://github.com/Andy234-andy/conscio/blob/main/Conscio/LICENSE"><img alt="License MIT" src="https://img.shields.io/badge/license-MIT-green"></a>
  <a href="https://andy234-andy.github.io/conscio/"><img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2013%2B-black"></a>
  <a href="#"><img alt="On-device AI" src="https://img.shields.io/badge/AI-on--device%20NLP-purple"></a>
</p>

Conscioは、Macのメニューバーに常駐する**文脈認識型デジタルナビゲーター**です。
いま最前面のアプリ・ドキュメントをリアルタイムで理解し、必要な情報だけをさりげなく提示します。そして、あなたが深く集中している瞬間を守ります。

> 🚀 最新: **v1.1.0 オンデバイスAI提案エンジン** · 🌐 公式サイト: https://andy234-andy.github.io/conscio/

## 🧬 進化ログ (Evolution Log)

| 日時 | 進化内容 |
|------|----------|
| 2026-10-18 08:xx | ✅ **進化#1**: 習慣データの永続化(再起動でも集中時間が消えない)＋アプリ終了ボタン |
| 2026-10-18 06:xx | ✅ v1.1.0: オンデバイスNLP (Apple NaturalLanguage) ＋ AI検索サジェスト |
| 2026-10-17 | ✅ v1.0.0: 初公開 (文脈認識/スマート提案/ノイズ抑制/習慣レポート) |

## ✨ 3つのコア機能

### 1. リアルタイム文脈認識 (Context Engine)
アクティブなアプリ・開いているドキュメントを2秒ごとに監視し、「今何をしているのか」を理解します。

### 1.5 🤖 オンデバイスAIキーワード抽出 (v1.1新機能)
Apple NaturalLanguage frameworkが、その文脈から重要キーワードを抽出し、「今欲しい検索」を自動サジェスト。**すべてMacの中だけで処理され、外部送信はゼロ**です。

### 2. スマート提案 (Smart Suggestion)
文脈に合わせて関連資料・リファレンス・タスクを提示。「検索する」という一手間を、ゼロにします。

### 3. インテリジェントノイズ抑制 (Focus Guard)
Xcode・Safari・Pagesなど「集中すべきアプリ」で作業している間、通知を自動で抑制。離れたときだけ、抑制した分のサマリーを届けます。

### 4. デジタル習慣レポート (Habit Report)
集中時間・文脈の切り替え頻度・使用アプリの統計をポジティブに可視化。「叱らない習慣化」がコンセプト。

## 🚀 使い方

```bash
# ビルド
swift build

# アプリを起動 (ビルド済みバイナリを.app化済み)
open Conscio.app
```

- メニューバーに 🧠 アイコンが現れます
- 初回のみ「アクセシビリティ許可」を出すと文脈認識が高精度になります

## 💡 なぜ世の中に必要か

 현代人の1日は、平均して **アプリを何百回も** 切り替え、通知に何十回も中断されています。
タスク管理ツールは増えたのに、私たちはますます「管理される側」になっている。

Conscioの思想はシンプルです。
**ツールが人に合わせて動き、人がツールに合わせる必要をなくす。**

## 📝 License

MIT
