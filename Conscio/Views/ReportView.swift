
import SwiftUI
import Charts // 🧬 進化#5: Swift Charts (macOS 13+)
import UniformTypeIdentifiers // 🧬 進化#84: CSV書き出しのUTType

struct ReportView: View {
    @ObservedObject var habitTracker: HabitTracker
    // 🧬 進化#84: CSV書き出しの結果表示 (保存先パス)
    @State private var exportMessage: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading) {
                        Text(L10n.t("report.title"))
                            .font(.title2)
                            .bold()
                        Text(L10n.t("report.subtitle"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)

                Divider()

                // Total Focus Time Card
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("report.totalFocus"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline) {
                        Text(habitTracker.formattedTotalFocusTime)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                        Spacer()
                        Text(L10n.t("report.praise"))
                            .font(.caption)
                            .padding(6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                    // 🧬 進化#92: 本日の不在(ロック) — #91で利用時間から除外した時間を毎日明示 (誇張ではなく正直な開示)
                    if habitTracker.todayLockMinutes > 0 {
                        Label(
                            String(format: L10n.t("report.lockToday"), habitTracker.todayLockMinutes),
                            systemImage: "lock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // 🧬 進化#96: オフライン集中 (紙作業など) の自主申告 — 画面計測と混ぜない明示ラベル
                    if habitTracker.todayManualMinutes > 0 {
                        Label(
                            String(format: L10n.t("report.manualToday"), habitTracker.todayManualMinutes),
                            systemImage: "notebook")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // 🧬 進化#98: 連続目標達成日数 (誇張のない実績としてのモチベーション)
                    if habitTracker.goalStreakDays > 0 {
                        Label(
                            String(format: L10n.t("report.goalStreak"), habitTracker.goalStreakDays),
                            systemImage: "flame")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // 🧬 進化#13: 直近7日合計カード
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("report.weekTotal"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline) {
                        Text(habitTracker.formattedLast7DaysTotal)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        Spacer()
                        // 🧬 進化#21: 連続集中日数 (ストリーク)
                        if habitTracker.focusStreakDays >= 2 {
                            Label(String.localizedStringWithFormat(L10n.t("report.streak"), habitTracker.focusStreakDays),
                                  systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text(L10n.t("report.streakNone"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(String.localizedStringWithFormat(L10n.t("report.weekPerAvg"), habitTracker.last7DaysAverageMinutes))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // 🧬 進化#89: 週次比較 (今週 vs 先週 — データ欠損日は0分扱い・誇張なし)
                    let prevMin = Int(habitTracker.previousWeekTotalSeconds / 60)
                    let nowMin = Int(habitTracker.last7DaysTotalSeconds / 60)
                    if prevMin > 0 {
                        let pct = (nowMin - prevMin) * 100 / prevMin
                        Text(String(format: L10n.t("report.weekCompare"), pct))
                            .font(.caption)
                            .foregroundColor(pct > 0 ? .green : (pct < 0 ? .orange : .secondary))
                    } else {
                        Text(L10n.t("report.weekCompareNA"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    // 🧬 進化#95: 直近7日の不在合計 (#91/93で集計から外した時間の開示 — 誇張ではなく説明)
                    if Int(habitTracker.last7DaysLockSeconds / 60) > 0 {
                        Text(String(format: L10n.t("report.weekLock"), Int(habitTracker.last7DaysLockSeconds / 60)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // 🧬 進化#5: 直近7日の集中時間チャート (Swift Charts)
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("report.chart7"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Chart(habitTracker.last7DaysFocus) { entry in
                        BarMark(
                            x: .value(L10n.t("report.chartDate"), entry.day),
                            y: .value(L10n.t("report.chartFocus"), entry.minutes)
                        )
                        .foregroundStyle(.purple.gradient)
                        .cornerRadius(3)
                    }
                    .frame(height: 130)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // 🧬 進化#77: 直近30日の集中チャート (月次ビュー — dailyFocusMapをそのまま使用・目標破線つき)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L10n.t("report.chart30"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        let avg30 = Int(habitTracker.last30DaysTotalSeconds / 60 / 30)
                        Text(String.localizedStringWithFormat(L10n.t("report.chart30Avg"), avg30))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Chart {
                        ForEach(habitTracker.last30DaysFocus) { entry in
                            AreaMark(
                                x: .value(L10n.t("report.chartDate"), entry.day),
                                y: .value(L10n.t("report.chartFocus"), entry.minutes)
                            )
                            .foregroundStyle(.purple.opacity(0.22).gradient)
                            .interpolationMethod(.catmullRom)
                            LineMark(
                                x: .value(L10n.t("report.chartDate"), entry.day),
                                y: .value(L10n.t("report.chartFocus"), entry.minutes)
                            )
                            .foregroundStyle(.purple)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .interpolationMethod(.catmullRom)
                        }
                        RuleMark(y: .value(L10n.t("report.chartFocus"), Double(HabitTracker.dailyGoalSeconds / 60)))
                            .foregroundStyle(.green.opacity(0.55))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text(L10n.target(Int(HabitTracker.dailyGoalSeconds / 60)))
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                    }
                    .frame(height: 110)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // 🧬 進化#10: スコアを実データから算出 (直近て勝拙計算に一回のみ呼び出し)
                let score = habitTracker.focusScore

                // Stats Grid
                HStack(spacing: 12) {
                    // Context Switch Count
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("report.switches"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String.localizedStringWithFormat(L10n.t("report.countTimes"), habitTracker.contextSwitchCount))
                            .font(.title3)
                            .bold()
                        Text(habitTracker.contextSwitchCount < 15 ? L10n.t("report.steady") : L10n.t("report.scattered"))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)

                    // Focus Score (🧬 進化#10: 実データ計算 — 偽値廃止)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("report.score"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(score.score) / 100")
                            .font(.title3)
                            .bold()
                            .foregroundColor(score.score >= 70 ? .green : (score.score >= 30 ? .orange : .red))
                        if let yesterday = score.yesterdaySeconds {
                            Text(String.localizedStringWithFormat(L10n.t("report.vsYesterday"), Int(yesterday / 60)))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        } else {
                            Text(L10n.t("report.firstDay"))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        Text(L10n.target(Int(HabitTracker.dailyGoalSeconds / 60)))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }

                // Top Apps Usage
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("report.topApps"))
                        .font(.headline)
                        .padding(.bottom, 4)

                    if habitTracker.topApps.isEmpty {
                        Text(L10n.t("report.noData"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(habitTracker.topApps) { stat in
                            HStack {
                                Image(systemName: "app.fill")
                                    .foregroundColor(.blue)
                                Text(stat.appName)
                                    .font(.body)
                                Spacer()
                                Text(String.localizedStringWithFormat(L10n.t("report.minutesShort"), Int(stat.durationInSeconds / 60)))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // 🧬 進化#28: データ保存の透明性フッター (実サイズ・実場所・検証ドキュメント誘導 — 誇張なし)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.t("report.dataFolder"))
                        .font(.headline)
                        .padding(.bottom, 2)
                    Text(L10n.t("report.dataPath"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String.localizedStringWithFormat(L10n.t("report.dataSize"), habitTracker.dataFileSizeKB))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(L10n.t("report.dataPrivacyHint"))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Button(L10n.t("report.openFolder")) {
                        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        NSWorkspace.shared.open(dir.appendingPathComponent("Conscio"))
                    }
                    .buttonStyle(.link)

                    // 🧬 進化#84: 直近30日をCSV書き出し (ユーザー選択先のみ・端末内完結・個人情報なし)
                    Button(L10n.t("report.exportCSV")) {
                        let panel = NSSavePanel()
                        panel.nameFieldStringValue = "conscio-focus-30days.csv"
                        panel.allowedContentTypes = [UTType.commaSeparatedText]
                        panel.canCreateDirectories = true
                        panel.begin { response in
                            guard response == .OK, let url = panel.url else { return }
                            do {
                                try habitTracker.last30DaysCSV().write(to: url, atomically: true, encoding: .utf8)
                                exportMessage = url.path
                            } catch {
                                exportMessage = "error: \(error.localizedDescription)"
                            }
                        }
                    }
                    .buttonStyle(.link)
                    if !exportMessage.isEmpty {
                        Text(String(format: L10n.t("report.exportDone"), exportMessage))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
        }
        .frame(width: 450, height: 560)
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(habitTracker: HabitTracker())
    }
}
