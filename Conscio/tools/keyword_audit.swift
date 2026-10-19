// 🧬 進化#44: キーワード抽出の自動監査ツール (デバッグ用・配布物には含めない)
// ContextMonitor.swift の抽出ロジック (#42 名詞限定 / #43 言語別閾値) を mirror し、
// 架空のサンプル窓タイトルに対する抽出結果を検証する。個人情報は含まない。
import Foundation
import NaturalLanguage

func isMeaningless(_ title: String, appName: String) -> Bool {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let lower = trimmed.lowercased()
    return trimmed.isEmpty
        || lower == "untitled"
        || lower == "無題"
        || trimmed == appName
        || lower == "page 1"
        || lower.hasPrefix("loading")
}

func extractKeywords(from title: String, appName: String) -> [String] {
    var keywords: [String] = []

    if isMeaningless(title, appName: appName) { return ["<_filtered>"] }

    let recognizer = NLLanguageRecognizer()
    recognizer.processString(title)
    let lang = recognizer.dominantLanguage
    let isJapanese = (lang == .japanese)

    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = title
    if let lang = lang {
        tagger.setLanguage(lang, range: title.startIndex..<title.endIndex)
    }
    var options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

    tagger.enumerateTags(in: title.startIndex..<title.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
        // 🧬 #42: 日本語は名詞のみ・欧米は名詞+動詞
        let isMeaningful = (tag == .noun) || (!isJapanese && tag == .verb)
        if isMeaningful {
            let word = String(title[range])
            let minLen = isJapanese ? 2 : 3 // 🧬 #43
            if word.count >= minLen { keywords.append(word) }
        }
        return true
    }

    // 🧬 #43+#44: フォールバック(日本語は語単位に精製・助詞/ひらがな語を除去)
    if keywords.isEmpty {
        let fbMinLen = isJapanese ? 2 : 3
        let particles: Set<String> = ["の", "を", "に", "は", "が", "で", "と", "も", "へ", "から", "まで", "より", "って"]
        let tokenizer = NLTokenizer(unit: .word)
        var collected: [String] = []
        for chunk in title.components(separatedBy: CharacterSet.alphanumerics.inverted) {
            if isJapanese {
                tokenizer.string = chunk
                tokenizer.enumerateTokens(in: chunk.startIndex..<chunk.endIndex) { range, _ in
                    let w = String(chunk[range])
                    let hiraganaOnly = !w.isEmpty && w.unicodeScalars.allSatisfy { (0x3040...0x309F).contains($0.value) }
                    if w.count >= fbMinLen, !particles.contains(w), !hiraganaOnly {
                        collected.append(w)
                    }
                    return true
                }
            } else if chunk.count >= fbMinLen {
                collected.append(chunk)
            }
        }
        keywords = collected
    }
    return keywords.isEmpty ? ["<_empty>"] : keywords
}

let samples: [(String, String)] = [
    ("無題", "TextEdit"),
    ("loading…", "Safari"),
    ("untitled", "Notes"),
    ("進化ログを見る", "メモ"),
    ("集中の高め方 — Qiita", "Google Chrome"),
    ("アルゴリズム入門", "YouTube"),
    ("数学の問題集", "プレビュー"),
    ("Evolution#43 — README.md", "Code"),
    ("Stack Overflow - Where Developers Learn", "Google Chrome"),
    ("How It Works - conscio Wiki", "Safari"),
    ("2026年度まとめ_第2稿", "TextEdit"),   // フォールバック経路のテスト
]

print("| 窓タイトル (架空) | 検出言語 | 抽出キーワード |")
print("|---|---|---|")
for (title, appName) in samples {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(title)
    let langName = recognizer.dominantLanguage.map { "\($0)" } ?? "nil"
    let result = extractKeywords(from: title, appName: appName).joined(separator: " / ")
    print("| \(title) | \(langName) | \(result) |")
}
