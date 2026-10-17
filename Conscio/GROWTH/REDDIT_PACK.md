# Reddit 投稿パック 🟥

## ⚠️ 事前ルール確認
Redditは自己宣伝に敏感。クセ:
- 50 karma 未満の新アカウントは「ツール紹介」投稿が規約違反されることがある
- 冒頭に「I made this」から入るとサクッと次に展開されない** → 痛みから始める

## r/macapps (最重要・最大リターン)

**Title:** Free menu bar app that pulls up the files you need based on what's on screen

**Body:**
```
Anyone else hit that mid-flow moment of "wait, where did I save that doc?" — and lose 10 minutes to Finder search?

That's why I built a tiny (1.5 MB) menu bar app. It watches your current app/document, then shows relevant files, docs and tasks in a popover. While you work in Xcode/Safari/Pages it also quiets notifications and hands you a digest when you're done.

- Free, open source (MIT)
- Runs fully on-device — no accounts, no telemetry
- macOS 13+, Apple Silicon

Keen for feedback, especially if it's brutally honest. What would make it an instant install for you?

Release: https://github.com/Andy234-andy/conscio/releases/latest
Site: https://andy234-andy.github.io/conscio/
```

## r/Swift (開発者向けストーリー)

**Title:** I shipped a macOS menu bar app without ever opening Interface Builder — SPM + hand-written Info.plist

**Body:**
```
Fun experiment: launched a menu bar app where the .app is literally assembled by hand around an SPM executable. Info.plist written in a text editor, binary copied in, ad-hoc codesigned, icon via AppKit script → iconutil.

What I learned:
- UNUserNotificationCenter silently throws away an app that has no bundle identifier — your app "quits" with zero errors
- AXUIElement (Accessibility) returns non-Optional handles, so Swift's if-let bindings fail at compile time — pattern-match AnyObject? carefully
- iconutil + sips is a perfectly valid icon pipeline. No .xcassets needed

Full writeup & MIT source: https://github.com/Andy234-andy/conscio
AMA if you want the gory details.
```

## r/productivity (価値染みる方)

**Title:** I stopped losing "10 minutes per document recall" with a menu bar companion (free)

**Body:**
```
Context switching is the invisible tax on deep work. I built a small companion that keeps a live model of what I'm doing (active app + doc) and quietly surfaces the right file/task at that moment. Also silences side notifications during focus blocks.

Runs 100% on-device, MIT, free. If you hate subscriptions like I do, this is refreshing: https://andy234-andy.github.io/conscio/
```

## 投稿タイミング
- r/macapps: 火曜-木曜 JST 夜〜 (US朝)
- r/Swift: 平日いつでも
- 各 subreddit は「自己紹介+フィードバック募集」文脈で必ず投稿する
