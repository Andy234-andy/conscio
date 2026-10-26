
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
    // 🧬 進化#92: 日ごとの不在(ロック)時間 (キー: yyyy-MM-dd) — #91で集計から外した時間を正直に可視化
    @Published var dayLockMap: [String: TimeInterval] = [:]
    // 🧬 進化#96: 日ごとのオフライン集中 (紙の作業など・キー: yyyy-MM-dd) — 画面計測と混ぜない自主申告データ
    @Published var manualFocusMap: [String: TimeInterval] = [:]
    // 🧬 進化#96: 手動セッションの開始時刻 (UserDefaultsで再起動後も残る)
    private var manualStartedAt: Date?

    // 🧬 進化#10: 実データベースの集中達成スコア (偽値88/100を置換)
    struct FocusScoreResult {
        let score: Int                      // 0-100 (目標60分/日の達成率)
        let todaySeconds: TimeInterval
        let yesterdaySeconds: TimeInterval? // nil = 昨日データなし
    }
    
    private var lastAppName: String?
    private var lastAppStartTime: Date?
    // 🧬 進化#56: ディスク書込スロットル用 (10秒に1回以下)
    private var lastDiskWrite: Date?
    // 🧬 進化#92: ロック区間の始点 (解除時に区間長を計算)
    private var suspendedAt: Date?
    private(set) var focusApps: Set<String> = {
        // 🧬 進化#94: 集中アプリをユーザーが管理できる (このMacのみに保存・ハードコード既定は初回のみのseed)
        // 背景: 既定リスト[Xcode/Safari/Pages/TextEdit/Code]と実際の使い方 (例: Chrome中心) が合致せず
        // 「集中」が恒久0になる不整合が判明。ユーザーの環境に合わせられない仕様は誇りに反するので設定化。
        if let saved = UserDefaults.standard.stringArray(forKey: "focusAppNames"), !saved.isEmpty {
            return Set(saved)
        }
        let seed = ["Xcode", "Safari", "Pages", "TextEdit", "Code"]
        UserDefaults.standard.set(seed, forKey: "focusAppNames")
        return Set(seed)
    }()

    /// 🧬 進化#94: 集中アプリを追加 (即UserDefaultsに保存・通知抑止側にも同期)
    func addFocusApp(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        objectWillChange.send()
        focusApps.insert(trimmed)
        UserDefaults.standard.set(focusApps.sorted(), forKey: "focusAppNames")
        NotificationCenter.default.post(name: Notification.Name("conscio.focusAppsChanged"), object: nil)
    }

    /// 🧬 進化#94: 集中アプリを削除 (既定アプリも削除可 — 初期値の誤配から自由にする)
    func removeFocusApp(_ name: String) {
        objectWillChange.send()
        focusApps.remove(name)
        UserDefaults.standard.set(focusApps.sorted(), forKey: "focusAppNames")
        NotificationCenter.default.post(name: Notification.Name("conscio.focusAppsChanged"), object: nil)
    }

    /// 🧬 進化#94: 設定UI用の表示順 (アルファベット順)
    var focusAppNamesSorted: [String] {
        return focusApps.sorted()
    }

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
        // 🧬 進化#92: 不在(ロック)時間の日次マップ (旧ファイル互換のため Optional)
        var dayLock: [String: TimeInterval]?
        // 🧬 進化#96: オフライン集中(自主申告)の日次マップ (旧ファイル互換のため Optional)
        var dayManual: [String: TimeInterval]?

        init(focus: TimeInterval, switches: Int, usage: [UsageEntry], dayFocus: [String: TimeInterval]?, recentApps: [String]?, dayLock: [String: TimeInterval]?, dayManual: [String: TimeInterval]?) {
            self.focus = focus
            self.switches = switches
            self.usage = usage
            self.dayFocus = dayFocus
            self.recentApps = recentApps
            self.dayLock = dayLock
            self.dayManual = dayManual
        }

        enum CodingKeys: String, CodingKey {
            case focus, switches, usage, dayFocus, recentApps, dayLock, dayManual
        }

        // 進化#5: 旧フォーマット(dayFocusなし)でもデコードできる
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            focus = try c.decode(TimeInterval.self, forKey: .focus)
            switches = try c.decode(Int.self, forKey: .switches)
            usage = try c.decode([UsageEntry].self, forKey: .usage)
            dayFocus = try c.decodeIfPresent([String: TimeInterval].self, forKey: .dayFocus)
            recentApps = try c.decodeIfPresent([String].self, forKey: .recentApps)
            dayLock = try c.decodeIfPresent([String: TimeInterval].self, forKey: .dayLock)
            dayManual = try c.decodeIfPresent([String: TimeInterval].self, forKey: .dayManual)
        }
    }

    // 🧬 進化#9: 「さっき見てた関連アプリに戻る」提案の材料
    // 直近履歴のうち「現在アプリ以外」で最初に見つかったもの (フォーカス級を優先)
    func recentRelatedApp(excluding currentApp: String) -> String? {
        let focusSet = focusApps // 🧬 進化#94: ハードコードをユーザー設定に統一
        for app in recentAppBuffer where app != currentApp {
            if focusSet.contains(app) { return app }
        }
        return recentAppBuffer.first { $0 != currentApp }
    }

    // 🧬 進化#10: スコア計算 (誠実な指標のみ・捏造なし)
    // 🧬 進化#75: 目標を設定で変更可能に (UserDefaults "dailyGoalMinutes"・既定60分・15〜240分に正規化・このMacにのみ保存)
    static var dailyGoalSeconds: TimeInterval {
        let mins = UserDefaults.standard.object(forKey: "dailyGoalMinutes") as? Int ?? 60
        return TimeInterval(max(15, min(240, mins)) * 60)
    }

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

    /// 🧬 進化#84: 直近30日をCSV形式で返す (date,focus_minutes — 端末内完結)
    func last30DaysCSV() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var lines = ["date,focus_minutes"]
        for offset in stride(from: -29, through: 0, by: 1) {
            let d = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let key = fmt.string(from: d)
            let minutes = Int((dailyFocusMap[key] ?? 0) / 60)
            lines.append("\(key),\(minutes)")
        }
        return lines.joined(separator: "\n")
    }

    /// 🧬 進化#77: 直近30日の集中エントリ (月次チャート用 — dailyFocusMapをそのまま使用)
    var last30DaysFocus: [DailyFocusEntry] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var result: [DailyFocusEntry] = []
        for offset in stride(from: -29, through: 0, by: 1) {
            let d = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let key = fmt.string(from: d)
            let label = String(key.suffix(5)).replacingOccurrences(of: "-", with: "/")
            result.append(DailyFocusEntry(day: label, minutes: (dailyFocusMap[key] ?? 0) / 60))
        }
        return result
    }

    /// 🧬 進化#77: 直近30日の合計秒数 (チャートと同一の集計期間)
    var last30DaysTotalSeconds: TimeInterval {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var total: TimeInterval = 0
        for offset in stride(from: -29, through: 0, by: 1) {
            let d = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            total += dailyFocusMap[fmt.string(from: d)] ?? 0
        }
        return total
    }

    /// 🧬 進化#89: 前の7日 (8〜14日前) の合計秒数 (週次比較用 — データ欠損日は0分扱い)
    var previousWeekTotalSeconds: TimeInterval {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var total: TimeInterval = 0
        for offset in stride(from: -13, through: -7, by: 1) {
            let d = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            total += dailyFocusMap[fmt.string(from: d)] ?? 0
        }
        return total
    }

    // 🧬 進化#98: 連続目標達成日数 (今日が未達でも昨日までの連続を数える・365日上限の安全停止)
    var goalStreakDays: Int {
        let goal = HabitTracker.dailyGoalSeconds
        var streak = 0
        var day = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        if (dailyFocusMap[dayKey(for: Date())] ?? 0) >= goal {
            streak += 1
        }
        var guardCount = 0
        while (dailyFocusMap[dayKey(for: day)] ?? 0) >= goal && guardCount < 365 {
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
            guardCount += 1
        }
        return streak
    }

    // 🧬 進化#100: 直近28日の集中ヒートマップ (level 0=なし 1=<25% 2=<50% 3=<100% 4=目標達成)
    func focusHeatmapLevels() -> [(day: Date, level: Int, minutes: Int)] {
        let cal = Calendar.current
        let goal = HabitTracker.dailyGoalSeconds
        var rows: [(day: Date, level: Int, minutes: Int)] = []
        rows.reserveCapacity(28)
        for offset in (0..<28).reversed() {
            let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let seconds = dailyFocusMap[dayKey(for: day)] ?? 0
            let minutes = Int(seconds / 60)
            let ratio = goal > 0 ? seconds / goal : 0
            let level = minutes == 0 ? 0 : (ratio < 0.25 ? 1 : ratio < 0.5 ? 2 : ratio < 1.0 ? 3 : 4)
            rows.append((day, level, minutes))
        }
        return rows
    }

    /// 🧬 進化#92: 本日の不在(ロック)分 (#91方針との対比で「使った時間」には数えない)
    var todayLockMinutes: Int {
        return Int((dayLockMap[dayKey(for: Date())] ?? 0) / 60)
    }

    // 🧬 進化#96: オフライン集中 (紙の作業など) の手動打刻
    // 画面計測とは混ぜない — ユーザーが自分で計った時間を「自主申告」として明示ラベルで表示する
    var isManualSessionActive: Bool {
        return manualStartedAt != nil
    }

    /// 進化#96: 実行中セッションの現在秒 (表示用)
    var runningManualSeconds: TimeInterval {
        guard let at = manualStartedAt else { return 0 }
        return Date().timeIntervalSince(at)
    }

    var todayManualMinutes: Int {
        return Int((manualFocusMap[dayKey(for: Date())] ?? 0) / 60)
    }

    /// 進化#96: 「紙の作業を開始」ボタン
    func startManualSession() {
        guard manualStartedAt == nil else { return }
        manualStartedAt = Date()
        saveManualAnchor()
    }

    /// 進化#96: 「停止」ボタン — 区間を日次マップへ集計
    func stopManualSession() {
        guard let at = manualStartedAt else { return }
        let seconds = Date().timeIntervalSince(at)
        manualStartedAt = nil
        if seconds > 0 {
            manualFocusMap[dayKey(for: Date()), default: 0] += seconds
        }
        saveManualAnchor()
        saveStats()
    }

    /// 進化#96: 開始時刻の UserDefaults 保存 (起動中に再起動が来てもセッションは続く)
    private func saveManualAnchor() {
        if let at = manualStartedAt {
            UserDefaults.standard.set(at.timeIntervalSince1970, forKey: "manualSessionStart")
        } else {
            UserDefaults.standard.removeObject(forKey: "manualSessionStart")
        }
    }

    /// 進化#96: 起動時に未終了セッションの復元 (開始時刻は UserDefaults)
    func restoreManualSession() {
        if let epoch = UserDefaults.standard.object(forKey: "manualSessionStart") as? TimeInterval {
            manualStartedAt = Date(timeIntervalSince1970: epoch)
        } else {
            manualStartedAt = nil
        }
    }

    // 🧬 進化#95: 直近7日の不在(ロック・無操作)合計秒 (週次カードに開示 — #91/92/93の系列)
    var last7DaysLockSeconds: TimeInterval {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let cal = Calendar.current
        var total: TimeInterval = 0
        for offset in stride(from: 0, through: -6, by: -1) {
            let d = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            total += dayLockMap[fmt.string(from: d)] ?? 0
        }
        return total
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
        restoreManualSession() // 🧬 進化#96: 未終了の手動セッションがあれば復元
    }

    private func loadStats() {
        guard let data = try? Data(contentsOf: storeURL),
              let snap = try? JSONDecoder().decode(HabitStatsSnapshot.self, from: data) else { return }
        totalFocusTimeSeconds = snap.focus
        contextSwitchCount = snap.switches
        appUsageList = snap.usage.map { AppUsageStats(appName: $0.name, durationInSeconds: $0.seconds) }
        dailyFocusMap = snap.dayFocus ?? [:]
        recentAppBuffer = snap.recentApps ?? []
        dayLockMap = snap.dayLock ?? [:] // 🧬 進化#92: 不在時間の復元
        manualFocusMap = snap.dayManual ?? [:] // 🧬 進化#96: 自主申告の復元
    }

    private func saveStats() {
        // �ILOGs 進化#56: ディスク書込は10秒スロットル (2秒ティックが連続書込しない・コメントの意図を実装に合わせる)
        if let last = lastDiskWrite, Date().timeIntervalSince(last) < 10 { return }
        lastDiskWrite = Date()
        let snap = HabitStatsSnapshot(focus: totalFocusTimeSeconds,
                                      switches: contextSwitchCount,
                                      usage: appUsageList.map { UsageEntry(name: $0.appName, seconds: $0.durationInSeconds) },
                                      dayFocus: dailyFocusMap,
                                      recentApps: recentAppBuffer,
                                      dayLock: dayLockMap,
                                      dayManual: manualFocusMap)
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

    // 🧬 進化#91: ロック/スクリーンセーバ中は利用秒数の集計を停止する
    // (不在時間を先頭アプリの利用時間として計上してしまう過大計上を防ぐ — 正直なデータ設計)
    private var suspended = false

    /// 進化#91: ロック状態の反映 (true=計上を一時停止・false=再開)
    func setSuspended(_ on: Bool) {
        guard suspended != on else { return }
        suspended = on
        if on {
            // 🧬 進化#92: ロック区間の始点を記録
            suspendedAt = Date()
            // ロック直前までの断片を一度だけ正しく計上してから止める
            // (lastAppNameを渡すのでアプリは変わらず・切替カウントも増えない)
            if let last = lastAppName, !last.isEmpty {
                recordContextChange(to: Context(activeApplication: last, keywords: []))
            }
        } else {
            // 🧬 進化#92: 不在(ロック)時間を日次で記録 (#91で利用時間から除外した時間の実測)
            if let at = suspendedAt {
                let seconds = Date().timeIntervalSince(at)
                if seconds > 0 {
                    dayLockMap[dayKey(for: Date()), default: 0] += seconds
                }
                suspendedAt = nil
                saveStats()
            }
            // 再開時: ロック期間を含めず、計測の始点だけ今に合わせる
            lastAppStartTime = Date()
        }
    }

    func recordContextChange(to context: Context) {
        let currentApp = context.activeApplication
        let now = Date()

        // 🧬 進化#91: 停止中は集計せず時計の始点だけ更新 (解除時の過大計上を防止・ディスク書込も抑制)
        if suspended {
            lastAppStartTime = now
            if lastAppName != currentApp {
                lastAppName = currentApp
            }
            return
        }

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

        saveStats() // 💾 進化#56: 10秒スロットル付き保存 (細かいデータはメモリにあり・最悪10秒分が失われるだけ)
    }

    // 🧬 進化#56: アプリ終了時は現在有効な値をそのままフラッシュ (スロットルを迂回)
    func flushStatsOnTerminate() {
        // 🧬 進化#92: ロック中に終了した場合も不在時間を記録してから保存
        if suspended, let at = suspendedAt {
            let seconds = Date().timeIntervalSince(at)
            if seconds > 0 {
                dayLockMap[dayKey(for: Date()), default: 0] += seconds
            }
        }
        lastDiskWrite = nil
        saveStats()
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

    /// 🧬 進化#28: データの透明性 — 保存中の統計ファイルの実サイズをKBで返す (実測値・飾りなし)
    var dataFileSizeKB: Double {
        let attrs = try? FileManager.default.attributesOfItem(atPath: storeURL.path)
        let bytes = (attrs?[FileAttributeKey.size] as? NSNumber)?.doubleValue ?? 0
        return bytes / 1024.0
    }
}
