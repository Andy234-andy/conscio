
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

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("ctx.header"))
                    .font(.headline)
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
                Text("集中時間: \(viewModel.habitTracker.formattedTotalFocusTime)")
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
            NSWorkspace.shared.launchApplication(name)
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

// 🧬 進化#8: 今日の集中ビッグ数字カード
// habitTracker自身を監視する子Viewに分離 (変更が即UIに反映されるように)
struct TodayFocusCard: View {
    @ObservedObject var tracker: HabitTracker

    var body: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
