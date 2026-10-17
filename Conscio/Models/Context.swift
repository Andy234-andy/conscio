
import Foundation

struct Context: Identifiable {
    let id = UUID()
    var activeApplication: String
    var activeDocument: String? = nil
    var activeURL: String? = nil
    var keywords: [String] = []
    var calendarEvents: [String] = []
}
