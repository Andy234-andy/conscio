
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
                        Text("Conscio デジタル習慣レポート")
                            .font(.title2)
                            .bold()
                        Text("今週の作業リズムとディープワークの分析")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)

                Divider()

                // Total Focus Time Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("総ディープワーク時間")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline) {
                        Text(habitTracker.formattedTotalFocusTime)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                        Spacer()
                        Text("素晴らしい集中力です！")
                            .font(.caption)
                            .padding(6)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // 🧬 進化#5: 直近7日の集中時間チャート (Swift Charts)
                VStack(alignment: .leading, spacing: 8) {
                    Text("直近7日の集中時間 (分)")
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

                // Stats Grid
                HStack(spacing: 12) {
                    // Context Switch Count
                    VStack(alignment: .leading, spacing: 4) {
                        Text("文脈切り替え回数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(habitTracker.contextSwitchCount) 回")
                            .font(.title3)
                            .bold()
                        Text(habitTracker.contextSwitchCount < 15 ? "非常に安定しています" : "少し散漫かもしれません")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)

                    // Focus Score
                    VStack(alignment: .leading, spacing: 4) {
                        Text("集中達成スコア")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("88 / 100")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.green)
                        Text("先週比 +12%")
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
                    Text("最も活用したアプリケーション")
                        .font(.headline)
                        .padding(.bottom, 4)

                    if habitTracker.topApps.isEmpty {
                        Text("まだ利用データが集計されていません。作業を継続すると表示されます。")
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
