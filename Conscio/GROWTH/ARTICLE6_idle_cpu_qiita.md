*本記事はAIアシストで執筆し、人間が内容を確認しています。実測値のみを記載し、推測は明示します。*

## きっかけ: CPU窃盗犯を駆除した午後

今日、自分のMacが熱くなっていました。調査すると、プロセス一覧に知らない名前がいました。

```
xmrig  /  pid 50902  /  稼働 9時間25分  /  CPU 417%
pool.hashvault.sh ─ Monero のマイニングプール
```

CPU窃盗型マルウェア（xmrig）です。killし、身に覚えのない LaunchAgent 2件（ランダム文字ファイル名・AppleScriptでURLを1文字ずつ組み立てる難読化型）を隔離、kit資材も証拠保全の上で/tmpから除去しました。排除と forensics の記録は前の記事（「macOS常駐アプリを安全に…」）と incident レポートに残してあります。

自分で書いている常駐アプリ（Conscio — macOSのメニューバーに住む文脈認識アプリ・端末内完結・通信コード0）がある身として、駆除直後に考えたのは:

**「ユーザーが誰もいない時間に、自分のアプリはシステムに触るべきでない」**

## 重いのはどの処理か（うちの場合）

Conscio は2秒ごとのハートビートで次を行います:

| 処理 | 中身 | 重さ |
|------|------|------|
| 最前面アプリの把握 | `NSWorkspace.frontmostApplication` | in-process・軽い |
| ウィンドウタイトル | AX API | in-process・軽い |
| **Safari/ChromeのURL** | **NSAppleScript（osascript相当・プロセス起動）** | **重い** |

URL取得はすでに **6秒ごと**（2秒ティックで2回スキップ）に絞ってありましたが、**ロック中・スクリーンセーバ中は誰もブラウザを見ていない** ので、「起動そのものがゼロ」が正しい設計です。

## 実装: 通知4種を監視して不在中は取得を止める

```swift
private func registerScreensaverObservers() {
    let dist = DistributedNotificationCenter.default()
    let onStartNames = [
        Notification.Name("com.apple.screensaver.didstart"),
        Notification.Name("com.apple.screenIsLocked"),   // loginwindow のロック
    ]
    let onStopNames = [
        Notification.Name("com.apple.screensaver.didstop"),
        Notification.Name("com.apple.screenIsUnlocked"), // 解除=復帰
    ]
    for name in onStartNames {
        workspaceObservers.append(dist.addObserver(
            forName: name, object: nil, queue: .main) { [weak self] _ in
            self?.screensaverActive = true
        })
    }
    for name in onStopNames {
        workspaceObservers.append(dist.addObserver(
            forName: name, object: nil, queue: .main) { [weak self] _ in
            self?.screensaverActive = false
            self?.urlFetchTick = 0   // 復帰後すぐに1回取得させる
        })
    }
}
```

URLの取得部には1条件を足すだけです:

```swift
if appName.contains("Safari") || appName.contains("Chrome") {
    if self.screensaverActive {
        activeURL = self.lastFetchedURL   // 直前値を表示・osascriptは起動しない
    } else {
        if self.urlFetchTick % 3 == 0 {   // 6秒ごと
            self.lastFetchedURL = self.fetchBrowserURL(for: appName)
        }
        self.urlFetchTick += 1
        activeURL = self.lastFetchedURL
    }
}
```

## つまずき1: NSWorkspace にスクリーンセーバ通知が無かった

最初は `NSWorkspace` の `.screensaverDidStartNotification` / `.screensaverDidStopNotification` を想定して書きましたが、**macOS 27 SDK のコンパイルで「そのメンバーは存在しない」が実測されました**:

```
error: type 'NSWorkspace' has no member 'screensaverDidStartNotification'
```

そこで名前に依存しない **`DistributedNotificationCenter` の実名4種**（上記コード）に差し替え。runtimeの文字列なのでSDKの変化に対して強い一方、**macOS内部の通知名は未文書化 (undocumented) 領域**なので、将来変わり得るリスクはコードのコメントに明示しています。

## つまずき2: cp直後の codesign 地雷

手作りの .app に新バイナリを `cp` してから再署名すると:

```
Conscio.app: resource fork, Finder information, or similar detritus not allowed
```

原因は **新バイナリが持つ拡張属性**（SPMのビルドが付与したad-hoc署名時点のメタ情報等）。対処は順序のみ:

```bash
xattr -cr Conscio.app                                  # 1) cp の後に必須
codesign --force --deep --sign - Conscio.app            # 2) 差し替え後の再署名
codesign --verify --deep --strict Conscio.app           # 3) 検証
```

手作業で .app を組み立てている方の典型地雷なので、手順は Wiki (Build-from-Source) に追記済みです。

## 限界を正直に

- **不在中にosascript起動がゼロになる設計**はコード/リリースで確定。ただし「ロック下の長時間実測」は、日常使用の中で継続観察しています（`health_check.sh` が毎回オフライン実測・負荷・xmrig不在を確認する仕組みなので、逸脱はティックで上がってくる）
- 通知4名は内部通知の文字列名を使うため、macOSの将来のバージョンで名前変化があれば（変化したら）参照先も更新 — コード内に明示してある状態です

## リリースと関連機能

本日、この省CPU改造は **v1.4.3** としてリリース済みです（同日バッチ機能: 「今日の集中目標を設定で変更可能[15〜240分Stepper・スコア/色/表記が動的追従]」とセット）。実SHA-256と検証手順はリポジトリの SECURITY.md に公開しています。

- リポジトリ: https://github.com/Andy234-andy/conscio
- リリース: https://github.com/Andy234-andy/conscio/releases/tag/v1.4.3

**不在時にはシステムに触らない。** これはCPU窃盗を経験から学んだ、常駐アプリの体温調整です。
