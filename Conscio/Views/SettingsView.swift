
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Text("Conscioの設定")
                .font(.largeTitle)
                .padding(.bottom)

            Section(header: Text("一般")) {
                Toggle("メニューバーに表示", isOn: .constant(true))
            }

            Section(header: Text("プライバシー")) {
                Button("パーミッションの管理") {
                    // Open System Settings relevant pane
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Section(header: Text("デジタル習慣")) {
                Toggle("週間レポートを有効にする", isOn: .constant(true))
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
