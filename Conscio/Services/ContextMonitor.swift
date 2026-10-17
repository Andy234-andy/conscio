
import Foundation
import Cocoa
import Combine

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
            
            // Basic keyword extraction (can be improved with NLP)
            keywords.append(appName)
            if let doc = activeDocument {
                keywords.append(contentsOf: doc.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
            }
            // For browser, we'd need browser-specific extensions or more complex Accessibility parsing
            // For now, let's manually add a placeholder for activeURL if app is a browser
            if appName.contains("Safari") || appName.contains("Chrome") {
                activeURL = "https://example.com/current-webpage" // Placeholder, actual implementation is complex
            }


            self.currentContext = Context(activeApplication: appName,
                                          activeDocument: activeDocument,
                                          activeURL: activeURL,
                                          keywords: Array(Set(keywords)),
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
