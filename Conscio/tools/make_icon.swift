// Conscio アプリアイコン生成スクリプト
import AppKit

let size: CGFloat = 1024
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// iOS/macOSスタイルの丸角矩形でクリップ
let radius: CGFloat = 230
let bg = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size), xRadius: radius, yRadius: radius)
bg.addClip()

// ネイビー→紫のグラデーション背景
let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.24, green: 0.32, blue: 0.75, alpha: 1.0),
    NSColor(calibratedRed: 0.55, green: 0.28, blue: 0.92, alpha: 1.0)
])
grad?.draw(in: bg, angle: 45)

// 中央に脳アイコン
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 600)]
let str = NSAttributedString(string: "🧠", attributes: attrs)
let strSize = str.size()
str.draw(at: NSPoint(x: (size - strSize.width) / 2, y: (size - strSize.height) / 2 + 20))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    print("ERROR: 変換失敗")
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outputPath))
print("OK: \(outputPath)")
