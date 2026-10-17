# 英語記事 (dev.to / Medium ビクトリー起草) 🇺🇸

## Title
**I built a context-aware menu bar app that quietly protects your focus — free, on-device, 1.5 MB**

## Body draft

### The problem nobody counts
Knowledge workers lose, on average, 20-30 minutes a day just *finding* things they already had. Task managers multiplied. Context quality collapsed.

Conscio (Latin: *to be aware*) targets the invisible tax: broken context.

### What it does
- A 2-second heartbeat reads your frontmost app and document via Accessibility APIs
- A popover surfaces the files, URLs, and tasks relevant to that context — before you search
- Focus mode declares focus apps (Xcode, Safari, Pages...): while you're inside one, notifications are held; when you surface, you get a clean digest
- A habit dashboard scores focus time / context switches *positively* — it never scolds

### Why on-device only
Three words: **no accounts. no telemetry.** Your context is the most intimate metadata you own. Making the privacy posture the default rather than a checkbox is the whole game.

### The build story (no Xcode required)
The .app is a hand-assembled bundle around a Swift Package Manager executable:
1. `swift build`
2. Craft a minimal `Info.plist` (CFBundleExecutable, LSUIElement...)
3. Copy the binary into `MyApp.app/Contents/MacOS/`
4. `codesign --force --sign -` (ad-hoc)
5. Generate icon via AppKit script → `iconutil` → `.icns`

Pitfalls worth sharing:
- `UNUserNotificationCenter` **silently kills** apps without a bundle ID
- `AXUIElementCreateApplication` returns non-Optional handles; `if let` on it fails to compile
- `xattr -cr` before re-signing, or macOS blocks you for "detritus"

### Come break it
MIT, free, no sign-up. Site: https://andy234-andy.github.io/conscio/ — GitHub: https://github.com/Andy234-andy/conscio

Next up: on-device NLP suggestions and macOS Focus Filters integration.
