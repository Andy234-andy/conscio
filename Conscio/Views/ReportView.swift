
import SwiftUI
import Charts // 🧬 進化#5: Swift Charts (macOS 13+)

struct ReportView: View {
    @ObservedObject var habitTracker: HabitTracker

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
                        Text(String.localizedStringWithFormat(L10n.t("report.weekPerAvg"), habitTracker.last7DaysAverageMinutes))
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
                            x: .value("日付", entry.day),
                            y: .value("集中", entry.minutes)
                        )
                        .foregroundStyle(.purple.gradient)
                        .cornerRadius(3)
                    }
                    .frame(height: 130)
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
                        Text("\(habitTracker.contextSwitchCount) 回")
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
                        Text(L10n.t("report.target"))
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
                                Text("\(Int(stat.durationInSeconds / 60)) 分")
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
