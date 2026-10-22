# Conscio の安全性設計と検証根拠（SECURITY.md）

> 本ドキュメントはAIアシストで作成し、人間が内容を確認しています。
> 最終更新: 2026-10-22（v1.4.5時点）

Conscio は macOS に常駐し、フロントアプリの名称や前面ウィンドウのタイトルを参照する「文脈認識」を行います。強い権限（アクセシビリティ）を扱うため、**安全性は主張ではなく根拠**で示す方針にしています。このページは、誰でも同じ検証を再実行できるコマンド付きの記録です。

## 1. 収集するデータ（最小化の原則）

保存されるのは、次の**3種類だけ**です:

| データ | 例 | 保存先 |
|--------|-----|--------|
| アプリ名 | Xcode / Chrome… | `~/Library/Application Support/Conscio/habitstats.json` |
| 利用秒数 | 1234.5 | 同上（1ファイルのみ） |
| セッション回数 / 連続日数 / 直近アプリ名リスト | — | 同上 |

**保存しないもの**: 文書タイトル・URL・本文・画像・個人情報。`activeDocument`（前面ウィンドウタイトル）は**メモリ上のみ**で、ポップオーバー表示とオフラインNLP解析にだけ使われ、ディスクには書き出されません。

検証方法 — スナップショット構造体はアプリ名と秒数しか持たない:

```bash
# リポジトリで実行
grep -n -A12 "struct HabitStatsSnapshot" Conscio/Services/HabitTracker.swift
```

## 2. 通信コードは存在しない

アプリ内の Swift ソースには、ネットワーク通信（`URLSession` / `dataTask` / `NWPathMonitor` 等）が**1行もありません**。

```bash
# 何も出力されなければ通信コードはゼロ
grep -rn -E "URLSession|dataTask|NWPathMonitor" --include="*.swift" Conscio/
```

UIフレームワークの間接リンク（`CFNetwork` 等）は存在しますが、アプリ自身が通信を開始するコードはありません。将来通信機能を加える場合は、このページを更新します。

## 3. 強い権限（アクセシビリティ）の扱い

- macOSの仕様上、フロントアプリのウィンドウタイトル取得にはアクセシビリティ許可が必要です。これは**許可しないと主要機能が動作しない**ための必須権限で、ユーザーがシステム設定で明示的にonにします。
- 取得したタイトルは①本人の画面にのみ表示、②端末内でのみNLP解析（NLTagger・オフライン）。**外部送信はありません**（§2の監査）。
- 無意味なタイトル（`Untitled` / `無題` / `loading…` など）は解析対象から除外しています（進化#24）。

## 4. 通知の内容方針

通知には「アプリ名＋集中分数」などの**実データのみ**を含めます。文書タイトルやURLを通知に載せません（画面ロック中の通知センターでも内容を漏らさないため）。

## 5. サンドボックスについて（正直な限界）

Conscioは**App Sandbox化していません**。理由: macOSの仕様上、サンドボックス付き実行では他アプリのウィンドウタイトルを参照するアクセシビリティAPI（本命機能の核）が制限されるためです。この限界と、代替として「通信ゼロ＋保存最小化＋検証可能」を清掃的に守る方針を取っています。

## 6. 配布物の検証（実行可能な手順）

- 配布zipは **Apple Silicon (arm64) 専用**・**ad-hoc署名**。未署名/他ソース版は入手不可とし、不明な配布元からのバイナリは避けてください。
- 不安があれば、リポジトリから自前ビルドを推奨（`Build from Source` のWiki参照）。
- リリースノートは必ずAI表明を含め、人間が確認してから公開しています。

### 6.1 実ハッシュ（GitHub Releasesで公開済みバイナリ）

```
Conscio-macOS-arm64-v1.4.0.zip  (1,759,665 bytes)
SHA-256 = ff41e959e4411132f6b5528b44484bb2789ba74ae9490fb8c56bc9d6b48907b3

Conscio-v1.4.1.zip  (1,784,579 bytes — 2026-10-20 re-upload 固有ID修正後)
SHA-256 = 7df73513120a66ac716161e947f4a92d57c9d456421a6f2fa6004646cf55d38b

Conscio-v1.4.2.zip  (1,786,153 bytes)
SHA-256 = 1ae2b6f94080a5dd83f54ee99f4dd5acac828acfb93d431808f65e2e18691055

Conscio-v1.4.3.zip  (1,797,516 bytes — 2026-10-20 #75/#76バッチ)
SHA-256 = 4addb5e9312a1a2a4d45761ddc417cfd920f5f8ed25f689766aa99b6cda54296

Conscio-v1.4.4.zip  (1,835,048 bytes — 2026-10-21 30日チャート/却下/CSVバッチ)
SHA-256 = a0aa9da6ae739d2d0e13c88e546d9d71a83a9ced8dc95f52cc65940a56907be5

Conscio-v1.4.5.zip  (1,890,971 bytes — 2026-10-22 正直データ設計バッチ #89〜#96)
SHA-256 = 04d72e88055934de7528ffdab6bfee1c98503620c01948a7c463dcbe4599bcfd
```

自分で確認する場合:

```bash
# 1コマンド検証 (進化#60: 同梱スクリプト — SHA-256照合+codesign+バンドルIDを一括)
./Conscio/tools/verify_release.sh Conscio-v1.4.2.zip 1ae2b6f94080a5dd83f54ee99f4dd5acac828acfb93d431808f65e2e18691055

# 手動でも同じことができます
shasum -a 256 Conscio-v1.4.2.zip
```

### 6.2 展開後の署名確認

```bash
# ad-hocでは "Signature=adhoc" と表示されます（正当な表示）
codesign -dv Conscio.app 2>&1 | grep Signature

# 改ざん検証（失敗時は非ゼロ終了します）
codesign --verify --deep --strict Conscio.app && echo "verified OK"

# arm64専用ビルドであることの確認
lipo -info Conscio.app/Contents/MacOS/Conscio
```

### 6.3 Gatekeeperについて（正直な注意）

ad-hoc署名のため、**初回起動時に「開発元を検証できません」ダイアログが出ます（仕様どおり）**。対処は「右クリック → 開く」か、システム設定 → プライバシーとセキュリティ → 「このまま開く」許可です。`spctl`（Gatekeeper）による自動承認はad-hoc署名では期待しないでください。

## 7. ルールの固定

`Conscio/RULES.md`（固定日付付き）。抜粋: 個人情報を出す/保存する/投稿しない、課金・有料登録しない、公開物は事前承認＋AI表明、誇張・捏造しない。

---

*連絡・質問は GitHub Issues でどうぞ: https://github.com/Andy234-andy/conscio*
