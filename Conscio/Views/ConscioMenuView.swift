
import SwiftUI

struct ConscioMenuView: View {
    @StateObject var viewModel = MainViewModel()
    @State private var showReportWindow = false

    var body: some View {
        VStack {
            HStack {
                Text("Conscio Context Navigator")
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
                .help("デジタル習慣レポートを表示")
            }
            .padding(.bottom, 2)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("現在の文脈:")
                    .font(.headline)
                HStack {
                    Text("アプリ:")
                        .foregroundColor(.secondary)
                    Text(viewModel.currentContext.activeApplication)
                        .bold()
                }
                if let doc = viewModel.currentContext.activeDocument {
                    HStack {
                        Text("ドキュメント:")
                            .foregroundColor(.secondary)
                        Text(doc)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)

            Divider()

            Text("提案されたアクティビティ:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if viewModel.suggestions.isEmpty {
                    Text("関連する提案はありません。")
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
                    Text(viewModel.isSuppressingNotifications ? "集中モード (通知抑制中)" : "通常モード")
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
