
import Foundation
import Combine

struct AppUsageStats: Identifiable {
    let id = UUID()
    let appName: String
    var durationInSeconds: TimeInterval
}

class HabitTracker: ObservableObject {
    @Published var totalFocusTimeSeconds: TimeInterval = 0
    @Published var contextSwitchCount: Int = 0
    @Published var appUsageList: [AppUsageStats] = []
    
    private var lastAppName: String?
    private var lastAppStartTime: Date?
    private var focusApps: Set<String> = ["Xcode", "Safari", "Pages", "TextEdit", "Code"]

    func recordContextChange(to context: Context) {
        let currentApp = context.activeApplication
        let now = Date()

        if let lastApp = lastAppName, let startTime = lastAppStartTime {
            let elapsed = now.timeIntervalSince(startTime)
            
            // Record focus time if it's a designated focus app
            if focusApps.contains(lastApp) {
                totalFocusTimeSeconds += elapsed
            }

            // Update app usage stats
            if let index = appUsageList.firstIndex(where: { $0.appName == lastApp }) {
                appUsageList[index].durationInSeconds += elapsed
            } else {
                appUsageList.append(AppUsageStats(appName: lastApp, durationInSeconds: elapsed))
            }

            // Track context switch if application changed
            if lastApp != currentApp {
                contextSwitchCount += 1
            }
        }

        lastAppName = currentApp
        lastAppStartTime = now
    }

    var formattedTotalFocusTime: String {
        let hours = Int(totalFocusTimeSeconds) / 3600
        let minutes = (Int(totalFocusTimeSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間 \(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    var topApps: [AppUsageStats] {
        return appUsageList.sorted(by: { $0.durationInSeconds > $1.durationInSeconds }).prefix(3).map { $0 }
    }
}
