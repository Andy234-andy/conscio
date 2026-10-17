
import Foundation

enum SuggestionType: String, CaseIterable, Identifiable {
    case document = "ドキュメント"
    case webPage = "ウェブページ"
    case communication = "コミュニケーション"
    case task = "タスク"
    case knowledge = "知識"

    var id: String { self.rawValue }
}

struct Suggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let url: URL?
    let contentPreview: String?
}
