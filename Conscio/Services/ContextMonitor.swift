
import Foundation
import Cocoa
import Combine
import NaturalLanguage

class ContextMonitor: ObservableObject {
    @Published var currentContext: Context = Context(activeApplication: "Unknown", keywords: [])

    /// 🧬 進化#33: アクセシビリティ許可の有無をUIから参照できる公開ヘルパ (把握したい返りはBoolだけ)
    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    // 🌐 進化#4: ブラウザURL取得用の状態
    private var urlFetchTick = 0
    private var lastFetchedURL: String?

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
            // 🧬 進化#34: 未使用だったローカルkeywordsを削除 (NLPは下のaiKeywordsに直書き)

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

            // 🧬 進化#24: 無意味なタイトルはドキュメント扱いしない
            // (空文字 / Untitled系 / アプリ名と同一 / 汎用プレースホルダ)
            if let doc = activeDocument {
                let trimmed = doc.trimmingCharacters(in: .whitespacesAndNewlines)
                let lower = trimmed.lowercased()
                let meaningless = trimmed.isEmpty
                    || lower == "untitled"
                    || lower == "無題"
                    || trimmed == appName
                    || lower == "page 1"
                    || lower == "starting page"
                    || lower == "start page"
                    || lower == "loading…"
                    || lower == "loading"
                if meaningless { activeDocument = nil }
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
                    // 🧬 進化#42: 日本語の窓タイトルからは名詞だけ収集 (動詞は「〜する」系のノイズになりやすい・記事#41の議論と一致)
                    let isMeaningful = (tag == .noun) || (!isJapanese && tag == .verb)
                    if isMeaningful {
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
            // 🧬 進化#43+: NLPが空のときのフォールバック分割 — 言語別の閾値(#42と同じ基準)に合わせる
            // 🧬 進化#44: 日本語チャンクはさらに語単位に精製 (監査で「区切りなし日本語が丸ごと1キーワード化」を実測 → 助詞・ひらがなのみの語を除去)
            if aiKeywords.isEmpty, let doc = activeDocument {
                let fbRecognizer = NLLanguageRecognizer()
                fbRecognizer.processString(doc)
                let fbIsJapanese = (fbRecognizer.dominantLanguage == .japanese)
                let fbMinLen = fbIsJapanese ? 2 : 3
                let particles: Set<String> = ["の", "を", "に", "は", "が", "で", "と", "も", "へ", "から", "まで", "より", "って"]
                let tokenizer = NLTokenizer(unit: .word)
                var collected: [String] = []
                for chunk in doc.components(separatedBy: CharacterSet.alphanumerics.inverted) {
                    if fbIsJapanese {
                        tokenizer.string = chunk
                        tokenizer.enumerateTokens(in: chunk.startIndex..<chunk.endIndex) { range, _ in
                            let w = String(chunk[range])
                            let hiraganaOnly = !w.isEmpty && w.unicodeScalars.allSatisfy { (0x3040...0x309F).contains($0.value) }
                            if w.count >= fbMinLen, !particles.contains(w), !hiraganaOnly {
                                collected.append(w)
                            }
                            return true
                        }
                    } else if chunk.count >= fbMinLen {
                        collected.append(chunk)
                    }
                }
                aiKeywords = collected
            }
            // 🌐 進化#4: ブラウザの実URLを取得する
            // Safari/ChromeはAppleScriptに公開させており、最前面タブのURLを正確に取得できる。
            // (以前の example.com プレースホルダーを置換)
            if appName.contains("Safari") || appName.contains("Chrome") {
                if self.urlFetchTick % 3 == 0 { // 負荷軽減: 2秒×3=6秒ごとに取得
                    self.lastFetchedURL = self.fetchBrowserURL(for: appName)
                }
                self.urlFetchTick += 1
                activeURL = self.lastFetchedURL
            }


            self.currentContext = Context(activeApplication: appName,
                                          activeDocument: activeDocument,
                                          activeURL: activeURL,
                                          keywords: Array(Set(aiKeywords).prefix(8)),
                                          calendarEvents: []) // Remove duplicates
            
            #if DEBUG
            print("Context Updated: App='\(appName)', Doc='\(activeDocument ?? "N/A")', URL='\(activeURL ?? "N/A")', Keywords=\(self.currentContext.keywords.joined(separator: ", ")))")
            #endif
        }
    }

    /// 🌐 進化#4: AppleScript経由で最前面タブのURLを取得 (Safari/Chrome対応)
    /// 初回実行時に「ConscioがSafari/Chromeを制御しようとしています」の権限ダイアログが出る(1度だけ)
    private func fetchBrowserURL(for appName: String) -> String? {
        let source: String
        if appName.contains("Safari") {
            source = "tell application \"Safari\" to get URL of front document"
        } else {
            source = "tell application \"Google Chrome\" to get URL of active tab of front window"
        }
        guard let script = NSAppleScript(source: source) else { return nil }
        var errorInfo: NSDictionary? = nil
        let result = script.executeAndReturnError(&errorInfo)
        if let url = result.stringValue, !url.isEmpty {
            return url
        }
        if let err = errorInfo {
            // 権限が未許可(-1743)の場合は静かにフォールバック: URLはnilのまま動作継続
            #if DEBUG
            print("🌐 URL取得エラー: \(err[NSAppleScript.errorMessage] ?? "unknown")")
            #endif
        }
        return nil
    }

    // Function to request Accessibility permissions
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessibilityEnabled {
            #if DEBUG
            print("Accessibility permissions are not granted. Please enable them in System Settings > Privacy & Security > Accessibility for Conscio.")
            #endif
            // You might want to provide a button in the UI to open System Settings directly
        }
    }
}
