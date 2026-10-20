
import Foundation

enum SuggestionType: String, CaseIterable, Identifiable {
    case document = "ドキュメント"
    case webPage = "ウェブページ"
    case communication = "コミュニケーション"
    case task = "タスク"
    case knowledge = "知識"
    case appSwitch = "アプリ切替" // 🧬 進化#12

    var id: String { self.rawValue }
}

struct Suggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let url: URL?
    let contentPreview: String?
    // 🧬 進化#12: appSwitch提案の切替先アプリ名
    var targetAppName: String? = nil
    // 🧬 進化#78: キーワード提案の元語 (却下機能で使用・却下済み語は同じ日は出ない)
    var keyword: String? = nil
}
