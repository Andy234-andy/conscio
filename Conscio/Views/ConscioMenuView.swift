
import SwiftUI

struct ConscioMenuView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var showReportWindow = false

    var body: some View {
        VStack {
            HStack {
                Text(L10n.t("menu.title"))
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    openReportWindow()
                }) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help(L10n.t("ui.reportHelp"))

                Button(action: {
                    openSettingsWindow()
                }) {
                    Image(systemName: "gearshape")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help(L10n.t("ui.settingsHelp"))

                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help(L10n.t("ui.quitHelp"))
            }
            .padding(.bottom, 2)

            Divider()

            // 🧬 進化#8: 今日の集中ビッグ数字 (モチベーション・プラス)
            TodayFocusCard(tracker: viewModel.habitTracker)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    openReportWindow() // 🧬 進化#16: カードタップでレポートを開く
                }
                .help(L10n.t("ui.todayFocusHelp"))

            // 🧬 進化#96: 紙の作業などオフライン集中の自計測ボタン (画面計測と混ぜない自主申告)
            ManualFocusRow(tracker: viewModel.habitTracker)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("ctx.header"))
                    .font(.headline)

                // 🧬 進化#33: アクセシビリティ未許可のときはpopover内で静かに案内 (推測が動かない理由を隠さない)
                if !ContextMonitor.isAccessibilityGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.t("menu.axNeeded"))
                                .font(.caption)
                                .bold()
                            Text(L10n.t("menu.axHint"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(L10n.t("menu.axOpen")) {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(10)
                }

                HStack {
                    Text(L10n.t("ctx.app"))
                        .foregroundColor(.secondary)
                    // 🧬 進化#15: 現在アプリの実アイコン
                    if let icon = viewModel.currentAppIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 18, height: 18)
                    }
                    Text(viewModel.currentContext.activeApplication)
                        .bold()
                }
                if let doc = viewModel.currentContext.activeDocument {
                    HStack {
                        Text(L10n.t("ctx.doc"))
                            .foregroundColor(.secondary)
                        Text(doc)
                            .lineLimit(1)
                    }
                }
                if let url = viewModel.currentContext.activeURL {
                    HStack {
                        Text(L10n.t("ctx.url"))
                            .foregroundColor(.secondary)
                        Text(url)
                            .lineLimit(1)
                            .textSelection(.enabled)
                            .truncationMode(.middle)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)

            Divider()

            Text(L10n.t("ui.suggestions"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if viewModel.suggestions.isEmpty {
                    Text(L10n.t("ui.noSuggestions"))
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.suggestions) { suggestion in
                        HStack {
                            Image(systemName: iconName(for: suggestion.type))
                                .frame(width: 20)
                            Text("\(suggestion.title)")
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            if let url = suggestion.url {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                                // 🧬 進化#78: キーワード提案は却下できる (却下済み語は同じ日は出ない)
                                if suggestion.keyword != nil {
                                    Button {
                                        viewModel.dismissKeywordSuggestion(suggestion.keyword ?? "")
                                    } label: {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help(L10n.t("ui.dismissHelp"))
                                }
                            } else if suggestion.type == .appSwitch, let appName = suggestion.targetAppName {
                                // 🧬 進化#12: 戻る提案は実際にそのアプリへ切り替えるアクション
                                Button {
                                    activateApp(named: appName)
                                } label: {
                                    Image(systemName: "return")
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                                .help(String(format: L10n.t("ui.returnToHelp"), appName))
                            }
                        }
                    }
                }
            }

            Divider()

            // Notification suppression status and Focus stats
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isSuppressingNotifications ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isSuppressingNotifications ? L10n.t("ui.focusMode") : L10n.t("ui.normalMode"))
                        .font(.caption)
                }
                Spacer()
                Text(String(format: L10n.t("ui.focusTime"), viewModel.habitTracker.formattedTotalFocusTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(width: 380, height: 320)
    }

    private func iconName(for type: SuggestionType) -> String {
        switch type {
        case .document: return "doc.text"
        case .webPage: return "safari"
        case .communication: return "bubble.left.and.bubble.right"
        case .task: return "checkmark.circle"
        case .knowledge: return "lightbulb"
        case .appSwitch: return "arrowshape.turn.up.left"
        }
    }

    /// 🧬 進化#12: アプリを実際に切り替える (実行中ならアクティベート、無ければ起動)
    private func activateApp(named name: String) {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }) {
            running.activate(options: [.activateAllWindows])
        } else {
            // 🧬 進化#34/36: 非推奨API群 (launchApplication/fullPath家族) を使わない起動 —
            // 標準ディレクトリから「<name>.app」を直接探して openApplication へ
            let fm = FileManager.default
            let roots = ["/Applications", "/System/Applications", NSHomeDirectory() + "/Applications"]
            let appURL = roots.lazy
                .map { URL(fileURLWithPath: $0).appendingPathComponent("\(name).app") }
                .first { fm.fileExists(atPath: $0.path) }
            if let appURL = appURL {
                NSWorkspace.shared.openApplication(at: appURL,
                                                   configuration: NSWorkspace.OpenConfiguration(),
                                                   completionHandler: nil)
            }
        }
    }

    private func openReportWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 560), // 進化#5チャートが508→560枠に合うよう修正
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = L10n.t("report.title")
        window.contentView = NSHostingView(rootView: ReportView(habitTracker: viewModel.habitTracker))
        window.makeKeyAndOrderFront(nil)
    }

    /// 🧬 進化#11: 設定ウィンドウ (ポップオーバーの⚙から / 旧: only ⌘,でしか開けなかった)
    private func openSettingsWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.center()
        window.title = L10n.t("settings.title")
        window.contentView = NSHostingView(rootView: SettingsView(habitTracker: viewModel.habitTracker))
        window.makeKeyAndOrderFront(nil)
    }
}

struct ConscioMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ConscioMenuView()
    }
}

// 🧬 進化#96: オフライン集中の自主申告ボタン行 (開始/停止)
struct ManualFocusRow: View {
    @ObservedObject var tracker: HabitTracker

    var body: some View {
        if tracker.isManualSessionActive {
            Button {
                tracker.stopManualSession()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle.fill")
                        .foregroundColor(.red)
                    Text(String(format: L10n.t("ui.manualStop"), Int(tracker.runningManualSeconds / 60)))
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .help(L10n.t("ui.manualStart"))
        } else {
            Button {
                tracker.startManualSession()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.and.outline")
                    Text(L10n.t("ui.manualStart"))
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .help(L10n.t("ui.manualStart"))
        }
    }
}

// 🧬 進化#8: 今日の集中ビッグ数字カード
// habitTracker自身を監視する子Viewに分離 (変更が即UIに反映されるように)
struct TodayFocusCard: View {
    @ObservedObject var tracker: HabitTracker

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t("ui.todayFocus"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(tracker.formattedTodayFocus)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: tracker.formattedTodayFocus)
            }
            Spacer()
            // 🧬 進化#90: 目標達成リング (#75のStepper設定値と連動・100%到達で緑化)
            let fraction = min(1.0, tracker.todayFocusSeconds / max(1, HabitTracker.dailyGoalSeconds))
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(fraction >= 1.0 ? Color.green : Color.purple,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy, value: fraction)
                Text("\(Int(fraction * 100))%")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(fraction >= 1.0 ? .green : .secondary)
            }
            .frame(width: 44, height: 44)
            .help(String(format: L10n.t("ui.todayGoalHelp"), Int(fraction * 100)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
