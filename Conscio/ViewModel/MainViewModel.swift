
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

        // 🧬 進化#91+#93: ロック or 5分以上の無操作 = 不在 → 集計を一時停止 (両方の「現在値」をORして反映)
        contextMonitor.$screensaverActive
            .sink { [weak self] locked in
                guard let self = self else { return }
                self.habitTracker.setSuspended(locked || self.contextMonitor.userIdleActive)
            }
            .store(in: &cancellables)

        // 🧬 進化#93: 無操作(5分)の開始/復帰も同じ集計停止に接続 (再開は入力の検出で自動)
        contextMonitor.$userIdleActive
            .sink { [weak self] idle in
                guard let self = self else { return }
                self.habitTracker.setSuspended(idle || self.contextMonitor.screensaverActive)
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

    /// 🧬 進化#78: キーワード提案の却下 (その語は「同じ日」は出さない・翌日は再登場=誤爆に寛容)
    private static let dismissedKeywordsKey = "dismissedKeywordSuggestions"

    private var dismissedKeywords: [String: String] {
        UserDefaults.standard.dictionary(forKey: MainViewModel.dismissedKeywordsKey) as? [String: String] ?? [:]
    }

    func dismissKeywordSuggestion(_ keyword: String) {
        guard !keyword.isEmpty else { return }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let today = fmt.string(from: Date())
        var dict = dismissedKeywords.filter { $0.value == today } // 期限切れを一掃
        dict[keyword] = today
        UserDefaults.standard.set(dict, forKey: MainViewModel.dismissedKeywordsKey)
        suggestions.removeAll { $0.keyword == keyword } // 即時非表示
    }

    private func isKeywordDismissed(_ keyword: String) -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let today = fmt.string(from: Date())
        return dismissedKeywords[keyword] == today
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
        // 🧬 進化#78: その日很短却下された語は候補から外す
        if let kw = context.keywords.first(where: { $0.count >= 3 && $0.lowercased() != appNameLower && !isKeywordDismissed($0) }) {
            if let q = kw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                newSuggestions.append(Suggestion(type: .knowledge,
                                                 title: String(format: L10n.t("ui.searchTitle"), kw),
                                                 url: URL(string: "https://duckduckgo.com/?q=\(q)"),
                                                 contentPreview: L10n.t("ui.searchNote"),
                                                 keyword: kw))
            }
        }

        // 🧬 進化#36: 本日の利用上位から提案を混合 (実データ・3分以上・戻る提案と重複しない)
        if newSuggestions.count < 2,
           let top = habitTracker.topApps.first(where: { $0.appName != context.activeApplication }) {
            let minutes = Int(top.durationInSeconds / 60)
            if minutes >= 3, !newSuggestions.contains(where: { $0.targetAppName == top.appName }) {
                newSuggestions.append(Suggestion(type: .appSwitch,
                                                 title: String(format: L10n.t("ui.topAppTitle"), top.appName, minutes),
                                                 url: nil,
                                                 contentPreview: L10n.t("ui.topAppNote"),
                                                 targetAppName: top.appName))
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
