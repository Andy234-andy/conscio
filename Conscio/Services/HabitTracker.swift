
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
    // 🧬 進化#5: 日ごとの集中時間 (キー: yyyy-MM-dd)
    @Published var dailyFocusMap: [String: TimeInterval] = [:]
    // 🧬 進化#9: 最近のアプリ履歴 (直近 Lionly=MAX_BUFFER nexus件・新着順)
    @Published var recentAppBuffer: [String] = []
    
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
        // 進化#5: 既存ファイルとの互換性のため Optional で追加
        var dayFocus: [String: TimeInterval]?
        // 進化#9: 最近アプリ履歴 (旧ファイル互換のため Optional)
        var recentApps: [String]?

        init(focus: TimeInterval, switches: Int, usage: [UsageEntry], dayFocus: [String: TimeInterval]?, recentApps: [String]?) {
            self.focus = focus
            self.switches = switches
            self.usage = usage
            self.dayFocus = dayFocus
            self.recentApps = recentApps
        }

        enum CodingKeys: String, CodingKey {
            case focus, switches, usage, dayFocus, recentApps
        }

        // 進化#5: 旧フォーマット(dayFocusなし)でもデコードできる
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            focus = try c.decode(TimeInterval.self, forKey: .focus)
            switches = try c.decode(Int.self, forKey: .switches)
            usage = try c.decode([UsageEntry].self, forKey: .usage)
            dayFocus = try c.decodeIfPresent([String: TimeInterval].self, forKey: .dayFocus)
            recentApps = try c.decodeIfPresent([String].self, forKey: .recentApps)
        }
    }

    // 🧬 進化#9: 「さっき見てた関連アプリに戻る」提案の材料
    // 直近履歴のうち「現在アプリ以外」で最初に見つかったもの (フォーカス級を優先)
    func recentRelatedApp(excluding currentApp: String) -> String? {
        let focusSet: Set<String> = ["Xcode", "Safari", "Pages", "TextEdit", "Code"]
        for app in recentAppBuffer where app != currentApp {
            if focusSet.contains(app) { return app }
        }
        return recentAppBuffer.first { $0 != currentApp }
    }

    /// 進化#5 レポートチャート用: 直近7日分 (ラベルは "M/d" 相当の短縮)
    struct DailyFocusEntry: Identifiable {
        var id: String { day }
        var day: String
        var minutes: Double
    }

    var last7DaysFocus: [DailyFocusEntry] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var result: [DailyFocusEntry] = []
        for offset in stride(from: -6, through: 0, by: 1) {
            let d = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let key = fmt.string(from: d)
            let label = String(key.suffix(5)).replacingOccurrences(of: "-", with: "/")
            result.append(DailyFocusEntry(day: label, minutes: (dailyFocusMap[key] ?? 0) / 60))
        }
        return result
    }

    // 🧬 進化#8: 今日の集中時間 (ポップオーバーのビッグ数字表示用)
    var todayFocusSeconds: TimeInterval {
        dailyFocusMap[dayKey(for: Date())] ?? 0
    }

    var formattedTodayFocus: String {
        let s = Int(todayFocusSeconds)
        if s >= 3600 {
            let h = s / 3600
            let m = (s % 3600) / 60
            return "\(h)時間\(m)分"
        }
        return "\(s / 60)分"
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
        dailyFocusMap = snap.dayFocus ?? [:]
        recentAppBuffer = snap.recentApps ?? []
    }

    private func saveStats() {
        let snap = HabitStatsSnapshot(focus: totalFocusTimeSeconds,
                                      switches: contextSwitchCount,
                                      usage: appUsageList.map { UsageEntry(name: $0.appName, seconds: $0.durationInSeconds) },
                                      dayFocus: dailyFocusMap,
                                      recentApps: recentAppBuffer)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: storeURL)
        }
    }

    /// 進化#5: 日次キー生成 (yyyy-MM-dd、ロケール固定で安定)
    private func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    func recordContextChange(to context: Context) {
        let currentApp = context.activeApplication
        let now = Date()

        if let lastApp = lastAppName, let startTime = lastAppStartTime {
            let elapsed = now.timeIntervalSince(startTime)
            
            // Record focus time if it's a designated focus app
            if focusApps.contains(lastApp) {
                totalFocusTimeSeconds += elapsed
                // 進化#5: 日次集計にも同じ秒数を加算
                dailyFocusMap[dayKey(for: now), default: 0] += elapsed
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

        // 🧬 進化#9: 直近アプリ履歴を更新 (先頭insert・重複除去・10件保持)
        if recentAppBuffer.first != currentApp {
            recentAppBuffer.removeAll { $0 == currentApp }
            recentAppBuffer.insert(currentApp, at: 0)
            if recentAppBuffer.count > 10 {
                recentAppBuffer = Array(recentAppBuffer.prefix(10))
            }
        }

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
