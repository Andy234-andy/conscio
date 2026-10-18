
import Foundation
import UserNotifications
import Combine

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var suppressedCount: Int = 0
    @Published var isSuppressing: Bool = false

    var focusApps: Set<String> = [] // Apps that are considered "focus apps"
    private var lastActiveFocusApp: String? // Track the last active focus app
    private var suppressStartedAt: Date? // 🧬 進化#22: セッション開始時刻

    override init() {
        super.init()
        // バンドルされていない実行ファイル（生バイナリ）で呼ぶとクラッシュするため保護
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = self
            requestNotificationPermissions()
        } else {
            print("ℹ️ アプリバンドル外のため通知機能をスキップしました")
        }
    }

    // Request notification permissions
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted.")
            } else if let error = error {
                print("Notification permissions denied: \(error.localizedDescription)")
            }
        }
    }

    // Set apps that should NOT have their notifications suppressed
    func setFocusApps(_ apps: Set<String>) {
        self.focusApps = apps
        print("Focus apps set to: \(focusApps)")
    }

    // Call this when user enters a "focus context"
    func startSuppressing(forActiveApp appName: String) {
        guard !isSuppressing else { return } // Already suppressing

        if focusApps.contains(appName) {
            isSuppressing = true
            lastActiveFocusApp = appName
            suppressStartedAt = Date() // 🧬 進化#22
            print("Started suppressing notifications for app: \(appName)")
            // Future improvement: Integrate with macOS Focus Filters API if available and user permits
        } else {
            // Not a focus app, no suppression
            print("Active app '\(appName)' is not a designated focus app. No suppression started.")
        }
    }

    // Call this when user leaves a "focus context"
    func stopSuppressing() {
        guard isSuppressing else { return } // Not suppressing

        isSuppressing = false

        // 🧬 進化#22: 解除通知を「実データのセッション報告」に全面刷新。
        // 旧実装は「N件の通知が抑制されました」と語ったが、macOSの仕様上 willPresent で
        // 見えるのは Conscio自体の通知のみ → 他アプリの件数を語るのは不誠実だった。
        // そこで: ①記録できる実データ (どのアプリで何分集中したか) を報告する
        //          ②自アプリの保留件数がある時だけ実数を添える (OS制限は透明に提示)
        var minutes = 0
        if let start = suppressStartedAt {
            minutes = max(0, Int(Date().timeIntervalSince(start) / 60))
        }
        let heldOwnCount = suppressedCount
        suppressedCount = 0
        suppressStartedAt = nil
        if let app = lastActiveFocusApp {
            showNotificationSummary(focusApp: app, minutes: minutes, heldOwnCount: heldOwnCount)
        }
        lastActiveFocusApp = nil
        print("Stopped suppressing notifications.")
    }

    // 🧬 進化#22: 実データベースのセッション報告通知
    func showNotificationSummary(focusApp: String, minutes: Int, heldOwnCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = L10n.t("notif.focusOffTitle")
        if heldOwnCount > 0 {
            content.body = String.localizedStringWithFormat(L10n.t("notif.sessionBodyHeld"),
                                                            focusApp, minutes, heldOwnCount)
        } else {
            content.body = String.localizedStringWithFormat(L10n.t("notif.sessionBody"),
                                                            focusApp, minutes)
        }
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification summary: \(error.localizedDescription)")
            }
        }
    }

    // UNUserNotificationCenterDelegate method to intercept notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Only suppress if we are actively suppressing and the notification is not from a focus app
        if isSuppressing {
            print("Intercepted notification: \(notification.request.content.title)")

            if lastActiveFocusApp != nil {
                // This is a conceptual check. Directly identifying the sending app from UNNotificationContent
                // is complex and often requires inspecting bundle identifiers.
                // For a real app, you might need to use Distributed Notifications or other means.
                // For now, if we are in suppression mode, we will suppress unless it's explicitly from our "focus app" (which is hard to determine here).
                
                // For demonstration, let's assume if we are suppressing, we suppress *all* notifications
                // that are not explicitly allowed. This is a very blunt instrument.
                // A better approach would be to use Focus Filters (macOS 12+) or advanced Accessibility APIs.
                print("Suppressing notification: \(notification.request.content.title)")
                suppressedCount += 1
                completionHandler([]) // Do not display the notification
                return
            }
        }
        completionHandler([.banner, .sound]) // Display notification normally
    }
}
