# Conscio 🧠

**"You shouldn't have to choose information. Only the information worth being chosen should be there."**

Conscio is a **context-aware digital navigator** that lives in your Mac's menu bar.
It understands the app and document on your screen in real time, quietly surfaces exactly what you need, and protects the moments you are deeply focused.

> 🚀 **Latest: [v1.3.0](https://github.com/Andy234-andy/conscio/releases/latest)** — 13 evolutions in 2 days · 🌐 Site: https://andy234-andy.github.io/conscio/ · 📖 [Wiki / Docs](https://github.com/Andy234-andy/conscio/blob/main/Conscio/Wiki/Home.md)

## ✨ Core Features

### 1. Real-time Context Engine
Monitors your frontmost app, document, and window title every 2 seconds — including **the live app icon** right in the popover, and the **actual URL** of the front tab in Safari/Chrome.

### 2. 🤖 On-device AI Keyword Extraction
Apple's NaturalLanguage framework pulls meaningful keywords out of your current context (auto language detection: **Japanese & English**). It suggests "the search you want right now." **Everything stays on your Mac — zero data leaves the device.**

### 3. Honest Smart Suggestions
Only *real* suggestions, never placeholder content:
- **"Return to 〇〇"** — one click actually switches you back to your recent relevant app (launches it if it isn't running)
- **On-device keyword search** — opens DuckDuckGo only when *you* click it

### 4. Intelligent Noise Suppression (Focus Guard)
While you work in focus apps (Xcode, Safari, Pages, TextEdit, VS Code…), notifications are silently held. When you're done, a single summary tells you how many were quietly kept out. The menu bar icon turns **purple** so you can see you're protected.

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
- Latest release: **v1.4.1** (see Releases)

## 💡 Why it matters

Modern knowledge workers switch context hundreds of times a day. Task managers keep multiplying, yet we feel MORE managed than managing.

Conscio's philosophy is simple:
**Tools should move toward people — never the other way around.**

## 📝 License

MIT

---

*This README was written with AI assistance and reviewed by a human.*
