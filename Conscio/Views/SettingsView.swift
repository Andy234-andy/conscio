import SwiftUI
import Cocoa

/// 🧬 進化#11: 本当に効く設定ウィンドウ
/// (旧実装の .constant(true) フェイストグル2個を廃止し、実行可能な操作のみを実装)
struct SettingsView: View {
    @ObservedObject var habitTracker: HabitTracker
    @State private var showResetConfirm = false

    private var dataDirectoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Conscio", isDirectory: true)
    }

    var body: some View {
        Form {
            Text(L10n.t("settings.title"))
                .font(.largeTitle)

            Section(header: Text(L10n.t("settings.language"))) {
                HStack {
                    Text(L10n.t("settings.uiLang"))
                    Spacer()
                    Text(L10n.isJapanese ? "日本語" : "English")
                        .foregroundColor(.secondary)
                }
                Text(L10n.t("settings.uiLangNote"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text(L10n.t("settings.privacy"))) {
                Button(L10n.t("settings.permissions")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button(L10n.t("settings.openDataFolder")) {
                    NSWorkspace.shared.open(dataDirectoryURL)
                }
                Text(L10n.t("settings.privacyNote"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                // 🧬 進化#27: 収集データの明細を本体UIで可視化 (実データの範囲のみ・誇張なし)
                Text(L10n.t("settings.collectedDetail"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Section(header: Text(L10n.t("settings.habits"))) {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Text(L10n.t("settings.reset"))
                }
                .alert(L10n.t("settings.resetConfirmTitle"), isPresented: $showResetConfirm) {
                    Button(L10n.t("settings.resetDo"), role: .destructive) {
                        habitTracker.resetAll()
                    }
                    Button(L10n.t("ui.cancel"), role: .cancel) { }
                } message: {
                    Text(L10n.t("settings.resetConfirmMsg"))
                }
                Text(L10n.t("settings.resetNote"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 430, height: 340)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(habitTracker: HabitTracker())
    }
}
