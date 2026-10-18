
import SwiftUI

@main
struct ConscioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use an empty window group since our main UI is the menu bar popover
        // This ensures the app launches and the AppDelegate takes over.
        WindowGroup {
            // ContentView will be displayed if the app is launched directly as a window
            // But our primary interaction is through the menu bar.
            ContentView()
        }
        .commands {
            // Remove default commands if not needed for a menu bar app
            CommandGroup(replacing: .appInfo) { }
            CommandGroup(replacing: .appTermination) { }
            CommandGroup(replacing: .help) { }
            // Add custom commands if necessary
        }

        Settings {
            // 🧬 進化#11: 設定を共有HabitTrackerと接続 (⌘,でも⚙でも同じデータを見る)
            SettingsView(habitTracker: HabitTracker.shared)
        }
    }
}
