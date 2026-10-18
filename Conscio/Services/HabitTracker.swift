
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

    // 💾 永続化 (Application Support/Conscio/habitstats.json)
    private var storeURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Conscio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("habitstats.json")
    }()

    private struct UsageEntry: Codable {
        var name: String
        var seconds: TimeInterval
    }

    private struct HabitStatsSnapshot: Codable {
        var focus: TimeInterval
        var switches: Int
        var usage: [UsageEntry]
    }

    init() {
        loadStats()
    }

    private func loadStats() {
        guard let data = try? Data(contentsOf: storeURL),
              let snap = try? JSONDecoder().decode(HabitStatsSnapshot.self, from: data) else { return }
        totalFocusTimeSeconds = snap.focus
        contextSwitchCount = snap.switches
        appUsageList = snap.usage.map { AppUsageStats(appName: $0.name, durationInSeconds: $0.seconds) }
    }

    private func saveStats() {
        let snap = HabitStatsSnapshot(focus: totalFocusTimeSeconds,
                                      switches: contextSwitchCount,
                                      usage: appUsageList.map { UsageEntry(name: $0.appName, seconds: $0.durationInSeconds) })
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: storeURL)
        }
    }

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
        saveStats() // 💾 10秒おき以上の変化時のみファイル書き込み(軽量)
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
