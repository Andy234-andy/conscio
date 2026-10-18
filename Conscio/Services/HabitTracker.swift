
import Foundation
import Combine

struct AppUsageStats: Identifiable {
    let id = UUID()
    let appName: String
    var durationInSeconds: TimeInterval
}

class HabitTracker: ObservableObject {
    // 🧬 進化#11: シングルトン (ポップオーバー/レポート/設定すべてで同じインスタンスを共有)
    static let shared = HabitTracker()

    @Published var totalFocusTimeSeconds: TimeInterval = 0
    @Published var contextSwitchCount: Int = 0
    @Published var appUsageList: [AppUsageStats] = []
    // 🧬 進化#5: 日ごとの集中時間 (キー: yyyy-MM-dd)
    @Published var dailyFocusMap: [String: TimeInterval] = [:]
    // 🧬 進化#9: 直近アプリ履歴 (直近=MAX_BUFFER nexus件・新着順)
    @Published var recentAppBuffer: [String] = []

    // 🧬 進化#10: 実データベースの集中達成スコア (偽値88/100を置換)
    struct FocusScoreResult {
        let score: Int                      // 0-100 (目標60分/日の達成率)
        let todaySeconds: TimeInterval
        let yesterdaySeconds: TimeInterval? // nil = 昨日データなし
    }
    
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

    // 🧬 進化#10: スコア計算 (誠実な指標のみ・捏造なし)
    private static let dailyGoalSeconds: TimeInterval = 3600 // 目標60分/日

    var focusScore: FocusScoreResult {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let todayS = dailyFocusMap[fmt.string(from: Date())] ?? 0
        let yDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yRaw = dailyFocusMap[fmt.string(from: yDate)] ?? -1
        let base = min(100.0, todayS / HabitTracker.dailyGoalSeconds * 100.0)
        return FocusScoreResult(score: Int(base.rounded()),
                                todaySeconds: todayS,
                                yesterdaySeconds: yRaw < 0 ? nil : yRaw)
    }

    // 🧬 進化#11: 習慣データ全リセット (保存ファイルも削除)
    func resetAll() {
        totalFocusTimeSeconds = 0
        contextSwitchCount = 0
        appUsageList = []
        dailyFocusMap = [:]
        recentAppBuffer = []
        lastAppName = nil
        lastAppStartTime = nil
        try? FileManager.default.removeItem(at: storeURL)
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
            return String(format: L10n.t("time.hLong"), h, m)
        }
        return String(format: L10n.t("time.mLong"), s / 60)
    }

    // 🧬 進化#13: 直近7日の合計集中秒数 (チャートと同一の集計期間)
    var last7DaysTotalSeconds: TimeInterval {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var total: TimeInterval = 0
        for offset in stride(from: -6, through: 0, by: 1) {
            let d = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            total += dailyFocusMap[fmt.string(from: d)] ?? 0
        }
        return total
    }

    var formattedLast7DaysTotal: String {
        let s = Int(last7DaysTotalSeconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        if h > 0 { return String(format: L10n.t("time.hLong"), h, m) }
        return String(format: L10n.t("time.mLong"), m)
    }

    var last7DaysAverageMinutes: Int {
        Int(last7DaysTotalSeconds / 7 / 60)
    }

    // 🧬 進化#21: 連続集中日数 (1分以上集中した日が何日連続か・今日or昨日から遡る)
    // 今日がまだ1分未満なら昨日起点で数える (日中作業中にストリークを殺さない配慮)
    var focusStreakDays: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var streak = 0
        var day = (dailyFocusMap[fmt.string(from: Date())] ?? 0) >= 60
            ? Date()
            : (cal.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        while (dailyFocusMap[fmt.string(from: day)] ?? 0) >= 60 {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? Date()
        }
        return streak
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
            return String(format: L10n.t("time.hLong"), hours, minutes)
        } else {
            return String(format: L10n.t("time.mLong"), minutes)
        }
    }

    var topApps: [AppUsageStats] {
        return appUsageList.sorted { a, b in
            if a.durationInSeconds != b.durationInSeconds {
                return a.durationInSeconds > b.durationInSeconds
            }
            // 🧬 進化#24: 同秒数は名前順に安定させる (更新のたびに順位がちらつかないように)
            return a.appName < b.appName
        }.prefix(3).map { $0 }
    }
}
