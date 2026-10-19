
import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var notificationManager: NotificationManager! // Keep a reference to NotificationManager
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize NotificationManager here to ensure its delegate is set early
        notificationManager = NotificationManager()
        // The delegate is set in NotificationManager's init, but we need to ensure UNUserNotificationCenter has our manager as its delegate.
        // It's already set in NotificationManager's init, so no explicit call needed here unless other UNNotificationCenter related setup is required.

        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Conscio")
            button.action = #selector(statusItemClicked(_:))
            // 🧬 進化#23: 左クリック=popover / 右クリック(またはCtrl+クリック)=quick menu を1ボタンで振り分け
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // アクセシビリティ権限のシステムプロンプトを表示（許可すると文脈認識が有効になる）
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        _ = AXIsProcessTrustedWithOptions(options)

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ConscioMenuView())

        // Request necessary permissions (example, actual implementation needs more detail)
        requestPermissions()

        // 🧬 進化#3: 集中モード(通知抑制中)はメニューバーアイコンが色替えされる視覚サイン
        notificationManager.$isSuppressing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] suppressing in
                self?.updateStatusBarIcon(suppressing: suppressing)
            }
            .store(in: &cancellables)
    }

    /// 進化#3: 集中モード中はアイコンが紫色の非テンプレートになり、「今、Conscioがあなたを守っている」を一目で伝える
    func updateStatusBarIcon(suppressing: Bool) {
        guard let button = statusItem?.button else { return }
        if suppressing {
            let image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: L10n.t("ui.iconFocused"))
            image?.isTemplate = false
            button.image = image
            button.contentTintColor = .systemPurple
        } else {
            let image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Conscio")
            image?.isTemplate = true
            button.image = image
            button.contentTintColor = nil
        }
    }

    @objc func statusItemClicked(_ sender: NSStatusBarButton?) {
        let event = NSApp.currentEvent
        // 🧬 進化#23: 右クリック (or Ctrl+クリック) → quick menu, 左クリック → popover
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showQuickMenu()
        } else {
            togglePopover(nil)
        }
    }

    /// 🧬 進化#23: 右クリック quick menu (レポート/設定/終了へのショートカット)
    private func showQuickMenu() {
        let menu = NSMenu()
        let report = NSMenuItem(title: L10n.t("ui.quickReport"),
                                action: #selector(openReportFromMenu), keyEquivalent: "")
        let settings = NSMenuItem(title: L10n.t("ui.quickSettings"),
                                  action: #selector(openSettingsFromMenu), keyEquivalent: "")
        let quit = NSMenuItem(title: L10n.t("ui.quickQuit"),
                              action: #selector(quitFromMenu), keyEquivalent: "")
        for item in [report, settings, quit] { item.target = self }
        menu.addItem(report)
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(quit)

        statusItem.menu = menu          // 一時的にメニューを差し込んで
        statusItem.button?.performClick(nil)  // クリック位置でメニューを開く
        statusItem.menu = nil           // 開き終えたら解除 (次の左クリックでpopoverを維持)
    }

    @objc func openReportFromMenu() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 450, height: 560),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered, defer: false)
        window.center()
        window.title = L10n.t("report.title")
        window.contentView = NSHostingView(rootView: ReportView(habitTracker: HabitTracker.shared))
        window.makeKeyAndOrderFront(nil)
    }

    @objc func openSettingsFromMenu() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.center()
        window.title = L10n.t("settings.title")
        window.contentView = NSHostingView(rootView: SettingsView(habitTracker: HabitTracker.shared))
        window.makeKeyAndOrderFront(nil)
    }

    @objc func quitFromMenu() {
        NSApp.terminate(nil)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func requestPermissions() {
        // This is a placeholder for actual permission requests.
        // Real implementation would involve checking accessibility permissions,
        // file access, calendar access, etc., and guiding the user to System Settings.
        #if DEBUG
        print("Requesting necessary permissions...")
        #endif
        // For example, to check Accessibility:
        // if !AXIsProcessTrusted() {
        //     print("Accessibility permissions not granted. Please enable in System Settings.")
        //     // Optionally, open System Settings to the correct pane
        // }
    }
}
