
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

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("ctx.header"))
                    .font(.headline)
                HStack {
                    Text(L10n.t("ctx.app"))
                        .foregroundColor(.secondary)
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
        }
    }

    private func openReportWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 420),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Conscio デジタル習慣レポート"
        window.contentView = NSHostingView(rootView: ReportView(habitTracker: viewModel.habitTracker))
        window.makeKeyAndOrderFront(nil)
    }
}

struct ConscioMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ConscioMenuView()
    }
}
