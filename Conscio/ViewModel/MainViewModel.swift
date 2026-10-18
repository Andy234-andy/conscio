
import Foundation
import AppKit
import Combine

class MainViewModel: ObservableObject {
    @Published var currentContext: Context
    @Published var suggestions: [Suggestion]
    @Published var isSuppressingNotifications: Bool = false

    @Published var habitTracker = HabitTracker.shared // 進化#11: 共有インスタンス
    // 🧬 進化#15: 現在アプリの実アイコン (popoverの文脈欄に表示)
    @Published var currentAppIcon: NSImage?

    private var contextMonitor = ContextMonitor()
    private var notificationManager = NotificationManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        _currentContext = Published(initialValue: Context(activeApplication: "Loading...", keywords: []))
        _suggestions = Published(initialValue: [])
        currentAppIcon = NSWorkspace.shared.icon(for: .application)

        notificationManager.setFocusApps(["Xcode", "Safari", "Pages", "TextEdit", "Code"])

        contextMonitor.$currentContext
            .sink { [weak self] context in
                guard let self = self else { return }
                self.currentContext = context
                self.updateAppIcon(for: context.activeApplication) // 🧬 進化#15
                self.generateSuggestions(for: context)
                self.handleNotificationSuppression(for: context)
                self.habitTracker.recordContextChange(to: context) // Record stats for HabitTracker
            }
            .store(in: &cancellables)
        
        notificationManager.$isSuppressing
            .assign(to: \.isSuppressingNotifications, on: self)
            .store(in: &cancellables)
    }

    /// 🧬 進化#15: 最前面アプリの実アイコンを取得 (実行中から探し、無ければ汎用アイコン)
    private func updateAppIcon(for appName: String) {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == appName }),
           let icon = running.icon {
            currentAppIcon = icon
        } else {
            currentAppIcon = NSWorkspace.shared.icon(for: .application)
        }
    }

    private func generateSuggestions(for context: Context) {
        var newSuggestions: [Suggestion] = []

        // 🧬 進化#17: デモ提案(存在しない文書・example.comリンク)を全面削除。
        // 提案は「本物」だけにする主義: ①直近アプリへの戻る提案 ②オンデバイスAI検索提案 のみ。

        // 🧬 進化#9+: 直近履歴から戻り先を提案 (進化#12で本物の切替アクション付き)
        if let returnApp = habitTracker.recentRelatedApp(excluding: context.activeApplication) {
            newSuggestions.append(Suggestion(type: .appSwitch,
                                             title: String(format: L10n.t("ui.returnTo"), returnApp),
                                             url: nil,
                                             contentPreview: L10n.t("ui.returnToNote"),
                                             targetAppName: returnApp))
        }

        // 🤖 AI (on-device NLP) による文脈検索サジェスト
        let appNameLower = context.activeApplication.lowercased()
        if let kw = context.keywords.first(where: { $0.count >= 3 && $0.lowercased() != appNameLower }) {
            if let q = kw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                newSuggestions.append(Suggestion(type: .knowledge,
                                                 title: String(format: L10n.t("ui.searchTitle"), kw),
                                                 url: URL(string: "https://duckduckgo.com/?q=\(q)"),
                                                 contentPreview: L10n.t("ui.searchNote")))
            }
        }

        self.suggestions = newSuggestions
    }

    private func handleNotificationSuppression(for context: Context) {
        let appName = context.activeApplication

        if notificationManager.focusApps.contains(appName) {
            notificationManager.startSuppressing(forActiveApp: appName)
            isSuppressingNotifications = true
        } else {
            notificationManager.stopSuppressing()
            isSuppressingNotifications = false
        }
    }
}
