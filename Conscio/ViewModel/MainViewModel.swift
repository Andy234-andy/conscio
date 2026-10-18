
import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var currentContext: Context
    @Published var suggestions: [Suggestion]
    @Published var isSuppressingNotifications: Bool = false

    @Published var habitTracker = HabitTracker.shared // 進化#11: 共有インスタンス

    private var contextMonitor = ContextMonitor()
    private var notificationManager = NotificationManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        _currentContext = Published(initialValue: Context(activeApplication: "Loading...", keywords: []))
        _suggestions = Published(initialValue: [])

        notificationManager.setFocusApps(["Xcode", "Safari", "Pages", "TextEdit", "Code"])

        contextMonitor.$currentContext
            .sink { [weak self] context in
                guard let self = self else { return }
                self.currentContext = context
                self.generateSuggestions(for: context)
                self.handleNotificationSuppression(for: context)
                self.habitTracker.recordContextChange(to: context) // Record stats for HabitTracker
            }
            .store(in: &cancellables)
        
        notificationManager.$isSuppressing
            .assign(to: \.isSuppressingNotifications, on: self)
            .store(in: &cancellables)
    }

    private func generateSuggestions(for context: Context) {
        var newSuggestions: [Suggestion] = []

        if context.activeApplication.contains("Xcode") || context.activeApplication.contains("Code") {
            newSuggestions.append(Suggestion(type: .document, title: "SwiftUI Layout Guide", url: URL(string: "https://developer.apple.com/documentation/swiftui/views-and-controls"), contentPreview: "Official Apple documentation for SwiftUI views."))
            newSuggestions.append(Suggestion(type: .webPage, title: "Stack Overflow: SwiftUI issues", url: URL(string: "https://stackoverflow.com/questions/tagged/swiftui"), contentPreview: "Community discussions on SwiftUI."))
            newSuggestions.append(Suggestion(type: .task, title: "Conscio: Implement Notification Suppression", url: nil, contentPreview: "Check `NotificationManager.swift` for details."))
        } else if context.activeApplication.contains("Safari") || context.activeApplication.contains("Chrome") {
            newSuggestions.append(Suggestion(type: .webPage, title: "最新のAIトレンド記事", url: URL(string: "https://example.com/ai-trends"), contentPreview: "AIに関する最新情報をまとめた記事。"))
            newSuggestions.append(Suggestion(type: .document, title: "研究ノート_ConscioのAIエンジン", url: nil, contentPreview: "AIエンジンの設計に関する私のメモ。"))
        } else if context.activeApplication.contains("Pages") || context.activeApplication.contains("TextEdit") {
            newSuggestions.append(Suggestion(type: .document, title: "過去のレポート_テーマA", url: nil, contentPreview: "同様のテーマで書かれた過去のレポートです。"))
            newSuggestions.append(Suggestion(type: .knowledge, title: "文章作成のコツ", url: nil, contentPreview: "効果的な文章を作成するためのヒント集。"))
        } else {
            newSuggestions.append(Suggestion(type: .knowledge, title: "デジタルウェルビーイングの重要性", url: nil, contentPreview: "デジタル環境での健康的な生活について。"))
        }

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
                                                 title: "「\(kw)」を検索",
                                                 url: URL(string: "https://duckduckgo.com/?q=\(q)"),
                                                 contentPreview: "AIが文脈から選んだキーワード"))
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
