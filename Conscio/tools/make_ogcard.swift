// Conscio OGプレビューカード生成スクリプト (1200x630)
import AppKit

let width: CGFloat = 1200
let height: CGFloat = 630
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "og-card.png"

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

// 深いネイビーの背景
NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.06, alpha: 1.0).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

// 案例：グロー粒子 (多层や事業合成)
if let ctx = NSGraphicsContext.current {
    let spots: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
        (200, 500, 420, NSColor(calibratedRed: 0.35, green: 0.55, blue: 1.0, alpha: 0.28)),
        (950, 550, 380, NSColor(calibratedRed: 0.72, green: 0.35, blue: 1.0, alpha: 0.24)),
        (600, 100, 500, NSColor(calibratedRed: 0.35, green: 0.45, blue: 1.0, alpha: 0.10))
    ]
    for (x, y, r, c) in spots {
        c.setFill()
        NSBezierPath(ovalIn: NSRect(x: x - r/2, y: y - r/2, width: r, height: r)).fill()
    }
}

// 左側：グローアイコン
let emojiAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 260)]
let emoji = NSAttributedString(string: "🧠", attributes: emojiAttrs)
emoji.draw(at: NSPoint(x: 90, y: 200))

// 中央右：タイトル
let title = NSMutableAttributedString()
title.append(NSAttributedString(string: "Conscio", attributes: [
    .font: NSFont.systemFont(ofSize: 110, weight: .heavy),
    .foregroundColor: NSColor.white
]))
title.draw(at: NSPoint(x: 430, y: 330))

// サブタイトル
let sub = NSMutableAttributedString()
sub.append(NSAttributedString(string: "あなたの集中を、Macが守る。", attributes: [
    .font: NSFont.systemFont(ofSize: 48, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.8, alpha: 1.0)
]))
sub.draw(at: NSPoint(x: 435, y: 250))

// タグライン
let tag = NSMutableAttributedString()
tag.append(NSAttributedString(string: "Context-aware menu bar navigator for macOS", attributes: [
    .font: NSFont.systemFont(ofSize: 30, weight: .light),
    .foregroundColor: NSColor(calibratedRed: 0.62, green: 0.68, blue: 0.85, alpha: 1.0)
]))
tag.draw(at: NSPoint(x: 437, y: 190))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    print("ERROR")
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outputPath))
print("OK: \(outputPath)")
