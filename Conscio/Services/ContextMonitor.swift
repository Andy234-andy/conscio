
import Foundation
import Cocoa
import Combine
import NaturalLanguage

class ContextMonitor: ObservableObject {
    @Published var currentContext: Context = Context(activeApplication: "Unknown", keywords: [])

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Start monitoring when the object is initialized
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    func startMonitoring() {
        // Invalidate any existing timer before starting a new one
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in // Check every 2 seconds
            self?.updateContext()
        }
    }

    private func updateContext() {
        DispatchQueue.main.async {
            let frontmostApp = NSWorkspace.shared.frontmostApplication
            let appName = frontmostApp?.localizedName ?? "Unknown Application"

            var activeDocument: String?
            var activeURL: String?
            var keywords: [String] = []

            // Attempt to get document/window title using Accessibility API
            if let pid = frontmostApp?.processIdentifier {
                let appElement = AXUIElementCreateApplication(pid)
                var focusedWindow: AnyObject?
                AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)

                if let windowElement = focusedWindow {
                    // Get window title
                    var windowTitle: AnyObject?
                    AXUIElementCopyAttributeValue(windowElement as! AXUIElement, kAXTitleAttribute as CFString, &windowTitle)
                    activeDocument = windowTitle as? String

                    // Try to get document path if available (e.g., in TextEdit, Xcode)
                    var documentPath: AnyObject?
                    AXUIElementCopyAttributeValue(windowElement as! AXUIElement, kAXDocumentAttribute as CFString, &documentPath)
                    if let pathURL = documentPath as? URL {
                        activeDocument = pathURL.lastPathComponent // Get only the file name
                    } else if let pathString = documentPath as? String {
                         // Sometimes it's a string, try to get last path component
                         activeDocument = (pathString as NSString).lastPathComponent
                    }
                }
            }
            
            // 🤖 オンデバイス NLP キーワード抽出 (Apple NaturalLanguage framework)
            var aiKeywords: [String] = []
            let nlpText = [appName, activeDocument ?? ""].joined(separator: " ")
            if !nlpText.trimmingCharacters(in: .whitespaces).isEmpty {
                // 進化#2: NLLanguageRecognizerで言語を自動判定し、タガーに明示設定する
                // (日本語など短いテキストで品詞タグ付けの精度が大きく上がる)
                let recognizer = NLLanguageRecognizer()
                recognizer.processString(nlpText)
                let detected = recognizer.dominantLanguage
                let isJapanese = (detected == .japanese)

                let tagger = NLTagger(tagSchemes: [.lexicalClass])
                tagger.string = nlpText
                if let lang = detected {
                    tagger.setLanguage(lang, range: nlpText.startIndex..<nlpText.endIndex)
                }
                let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]
                tagger.enumerateTags(in: nlpText.startIndex..<nlpText.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
                    if tag == .noun || tag == .verb {
                        let word = String(nlpText[range])
                        // 日本語は2文字で意味を持つ名詞が多い。欧米系は3文字以上
                        let minLen = isJapanese ? 2 : 3
                        if word.count >= minLen {
                            aiKeywords.append(word)
                        }
                    }
                    return true
                }
            }
            // NLPが空のときのフォールバック: 単純分割
            if aiKeywords.isEmpty, let doc = activeDocument {
                aiKeywords = doc.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 }
            }
            // For browser, we'd need browser-specific extensions or more complex Accessibility parsing
            // For now, let's manually add a placeholder for activeURL if app is a browser
            if appName.contains("Safari") || appName.contains("Chrome") {
                activeURL = "https://example.com/current-webpage" // Placeholder, actual implementation is complex
            }


            self.currentContext = Context(activeApplication: appName,
                                          activeDocument: activeDocument,
                                          activeURL: activeURL,
                                          keywords: Array(Set(aiKeywords).prefix(8)),
                                          calendarEvents: []) // Remove duplicates
            
            print("Context Updated: App='\(appName)', Doc='\(activeDocument ?? "N/A")', URL='\(activeURL ?? "N/A")', Keywords=\(self.currentContext.keywords.joined(separator: ", ")))")
        }
    }

    // Function to request Accessibility permissions
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessibilityEnabled {
            print("Accessibility permissions are not granted. Please enable them in System Settings > Privacy & Security > Accessibility for Conscio.")
            // You might want to provide a button in the UI to open System Settings directly
        }
    }
}
