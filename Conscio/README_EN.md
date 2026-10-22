# Conscio 🧠

**"You shouldn't have to choose information. Only the information worth being chosen should be there."**

Conscio is a **context-aware digital navigator** that lives in your Mac's menu bar.
It understands the app and document on your screen in real time, quietly surfaces exactly what you need, and protects the moments you are deeply focused.

> 🚀 **Latest: [v1.4.5](https://github.com/Andy234-andy/conscio/releases/latest)** — evolutions continuous (#96 as of Oct 22) · 🌐 Site: https://andy234-andy.github.io/conscio/ · 📖 [Wiki / Docs](https://github.com/Andy234-andy/conscio/blob/main/Conscio/Wiki/Home.md)

## ✨ Core Features

### 1. Real-time Context Engine
Monitors your frontmost app, document, and window title every 2 seconds — including **the live app icon** right in the popover, and the **actual URL** of the front tab in Safari/Chrome.

### 2. 🤖 On-device AI Keyword Extraction
Apple's NaturalLanguage framework pulls meaningful keywords out of your current context (auto language detection: **Japanese & English**). It suggests "the search you want right now." **Everything stays on your Mac — zero data leaves the device.**

### 3. Honest Smart Suggestions
Only *real* suggestions, never placeholder content:
- **"Return to 〇〇"** — one click actually switches you back to your recent relevant app (launches it if it isn't running)
- **On-device keyword search** — opens DuckDuckGo only when *you* click it

### 4. Focus Guard (measured, honestly)
While you work in focus apps (Xcode, Safari, Pages, TextEdit, VS Code…), Conscio quietly *measures* your real focus session. When you step away, it reports the actual minutes — **never fabricated notification counts** (macOS does not allow reading other apps' notifications, and we say so). The menu bar icon turns **purple** while a focus session is live.

### 5. Digital Habit Report
- **Today's focus** as a big number right in the popover (tap it to open the full report)
- **Last-7-days total** + daily average
- **7-day focus chart** (Swift Charts)
- **Real goal-based focus score** (0–100, goal: 60 min/day) with yesterday comparison — no vanity numbers, ever
- Context switches and top-apps ranking
- All stats persist in a single local JSON file

### 6. Real Settings
A gear button opens an actual settings window: reset habit data (with confirmation), open the data folder in Finder, manage permissions. No fake toggles.

## 🚀 Getting Started

1. Download the zip from [Releases](https://github.com/Andy234-andy/conscio/releases/latest), drag **Conscio.app** to Applications
2. **Right-click → Open** on first launch (ad-hoc signed, no Apple Developer certificate)
3. Grant **Accessibility** permission (prompted automatically) — that's the heart of context awareness
4. Look for the 🧠 icon in your menu bar

Build from source:

```bash
git clone https://github.com/Andy234-andy/conscio.git
cd conscio && swift build
```

## 🔒 Privacy

- All processing happens **on your Mac**
- Stats live in exactly one file: `~/Library/Application Support/Conscio/habitstats.json` — app *names* and usage *seconds* only; window titles are never written to disk
- **No outbound networking**: the sources contain zero `URLSession`/`dataTask` code — reproducible audit commands live in [`SECURITY.md`](SECURITY.md)
- Notifications carry app names and session minutes only — never document titles
- Honest limitation: the app is **not App-Sandboxed** (macOS restricts reading other apps' window titles from sandboxed processes), so the safety posture is *zero networking + minimal storage + reproducible verification* instead
- No telemetry, no account, no purchases — MIT licensed

## 🧬 Evolution highlights (2 days, 66 ticks and counting)

- **v1.4.4** — 30-day focus chart with goal line synced to the stepper, dismissable keyword suggestions (auto-resurface next day), CSV export to a user-chosen location
- **v1.4.3** — configurable daily focus goal (15–240 min stepper, default 60; score, colors and labels adapt) + idle saving: AppleScript URL fetching fully paused while the screen is locked / screensaver is on
- **v1.4.2** — stats disk writes throttled to once per 10s (was every 2s tick) + flush on terminate; runtime health check tool (`tools/health_check.sh`) and a one-command release verify script (`tools/verify_release.sh`)

- **v1.4.0** — real-app icon in popover, click-to-report flow, demo-suggestion cleanup, focus streak 🔥, honest Focus Guard wording, quick menu
- **v1.4.1** — NLTagger audit discovered Japanese POS tags never activate (all `OtherWord`); keyword fallback now does word-level refinement (particles and hiragana-only words dropped). Ships a debug audit tool (`tools/keyword_audit.swift`)
- **Privacy audit (2026-10-20)** — bundle ID contained the build machine's username; neutralized to `com.conscio.menubar`, affected release zip replaced. Details: [PRIVACY_AUDIT_2026-10-20.md](GROWTH/PRIVACY_AUDIT_2026-10-20.md)

Related write-ups (Japanese): [Qiita series ×5](https://qiita.com/Atsuki33) ・ [note essay](https://note.com/fine_thyme7447/n/n317579949e7d)
- Latest release: **v1.4.3** (see Releases)

## 💡 Why it matters

Modern knowledge workers switch context hundreds of times a day. Task managers keep multiplying, yet we feel MORE managed than managing.

Conscio's philosophy is simple:
**Tools should move toward people — never the other way around.**

## 🔒 Verifying a release zip (one command)

Downloaded a `Conscio-v*.zip`? Verify it with the bundled script (no network needed; extraction happens in a temp dir and is cleaned up):

```zsh
git clone https://github.com/Andy234-andy/conscio.git
./conscio/Conscio/tools/verify_release.sh Conscio-v1.4.2.zip \
  1ae2b6f94080a5dd83f54ee99f4dd5acac828acfb93d431808f65e2e18691055
# ✅ SHA-256 match → ✅ codesign verify passed → bundle ID & version printed
```

Expected hashes for every release: [SECURITY.md §6.1](SECURITY.md). If verification fails, do NOT launch the app.

*Evolution #60 (2026-10-20) — script version of the "verify your download" steps that shipped in Evolution #30.*

## 📝 License

MIT

## 📜 Changelog

Version-by-version details: [CHANGELOG.md](CHANGELOG.md) (all 7 releases; every note written with AI assistance and human-reviewed).

---

*This README was written with AI assistance and reviewed by a human.*
