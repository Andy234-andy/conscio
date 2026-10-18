import Foundation

/// 🧬 進化#6: 多言語化の下地 — UI文言の一元管理 (ja / その他はen)
/// Xcodeプロジェクトなし(SPM+手作り.app)ではString Catalogが扱いにくいため、
/// まずコード内辞書で言語切替できる「下地」を用意する。将来 .xcstrings への移行も容易。
enum L10n {
    static let isJapanese = Locale.current.language.languageCode?.identifier == "ja"

    private static let table: [String: (ja: String, en: String)] = [
        "menu.title":        ("Conscio Context Navigator", "Conscio Context Navigator"),
        "ctx.header":        ("現在の文脈:", "Current context:"),
        "ctx.app":           ("アプリ:", "App:"),
        "ctx.doc":           ("ドキュメント:", "Document:"),
        "ctx.url":           ("URL:", "URL:"),
        "ui.suggestions":    ("提案されたアクティビティ:", "Suggested activities:"),
        "ui.noSuggestions":  ("関連する提案はありません。", "No related suggestions yet."),
        "ui.reportHelp":     ("デジタル習慣レポートを表示", "Show digital habit report"),
        "ui.quitHelp":       ("Conscioを終了", "Quit Conscio"),
        "ui.focusMode":      ("集中モード", "Focus mode"),
        "ui.normalMode":     ("通常モード", "Normal mode"),
        "ui.todayFocus":     ("今日の集中", "Focus today"),
        "report.score":      ("集中達成スコア", "Focus score"),
        "report.vsYesterday":("昨日は %d 分", "Yesterday: %d min"),
        "report.firstDay":   ("2日目から昨日比が表示されます", "Comparison shows from day 2"),
        "report.target":     ("目標 60分/日", "Goal: 60 min/day"),
        "report.weekTotal":  ("直近7日の合計", "Last 7 days total"),
        "report.weekPerAvg": ("1日平均: %d分", "Daily avg: %d min"),
        "settings.title":    ("Conscioの設定", "Conscio Settings"),
        "settings.language": ("言語", "Language"),
        "settings.uiLang":   ("UIの表示言語", "UI language"),
        "settings.uiLangNote": ("macOSのシステム言語に従います（現在は日本語/英語の自動判別）", "Follows macOS system language (auto ja/en)"),
        "settings.privacy":  ("プライバシー", "Privacy"),
        "settings.permissions": ("パーミッションを管理（システム設定を開く）", "Manage permissions (opens System Settings)"),
        "settings.openDataFolder": ("データ保存フォルダをFinderで開く", "Open data folder in Finder"),
        "settings.privacyNote": ("統計はこのフォルダの1ファイルにだけ保存され、外部送信は行いません。", "Stats live in a single file here — nothing is ever sent."),
        "settings.collectedDetail":  ("保存内容: アプリ名・利用秒数・セッション回数のみ。文書タイトル・URL・個人情報は保存せず、通信コードは含みません（ソース監査済み）。", "Stored: app names, usage seconds and session counts only. No document titles, URLs or personal data; no networking code at all (source-audited)."),
        "settings.habits":   ("デジタル習慣", "Digital habits"),
        "settings.reset":    ("習慣データをリセット", "Reset habit data"),
        "settings.resetConfirmTitle": ("本当にリセットしますか？", "Really reset?"),
        "settings.resetConfirmMsg": ("すべての習慣データが削除されます。この操作は元に戻せません。", "All habit data will be deleted. This cannot be undone."),
        "settings.resetDo":  ("リセットする", "Reset"),
        "ui.cancel":         ("キャンセル", "Cancel"),
        "ui.settingsHelp":   ("設定を開く", "Open settings"),
        "ui.returnTo":       ("「%@」に戻る", "Return to \"%@\""),
        "ui.returnToNote":   ("クリックでアプリを切り替えます", "Click to switch apps"),
        "ui.returnToHelp":   ("%@ に切り替える", "Switch to %@"),
        "ui.todayFocusHelp": ("クリックで習慣レポートを開く", "Click to open the habit report"),
        "ui.searchTitle":    ("「%@」を検索", "Search \"%@\""),
        "ui.searchNote":     ("AIが文脈から選んだキーワード", "Keyword picked from context by on-device AI"),
        "notif.focusOffTitle": ("Conscio: 集中モードを解除しました", "Conscio: Focus mode off"),
        "notif.sessionBody": ("%@ での集中セッション: %d分", "Focus session in %@: %d min"),
        "notif.sessionBodyHeld": ("%@ での集中セッション: %d分 (Conscio自身の%d件は保留)", "Focus session in %@: %d min (%d of Conscio's own alerts held)"),
        "notif.focusOffBody": ("集中モード中に%d件の通知が抑制されました。", "%d notifications were quietly held during focus mode."),
        "ui.focusTime":      ("集中時間: %@", "Focus time: %@"),
        "report.chartDate":  ("日付", "Date"),
        "report.chartFocus": ("集中", "Focus"),
        "report.countTimes": ("%d 回", "%d times"),
        "report.minutesShort": ("%d分", "%d min"),
        "time.hLong":        ("%d時間%d分", "%dh %dm"),
        "time.mLong":        ("%d分", "%d min"),
        "report.streak":     ("%d日連続集中", "%d-day focus streak"),
        "report.streakNone": ("連続記録スタート！", "Start your streak!"),
        "ui.iconFocused":    ("Conscio (集中モード中)", "Conscio (focus mode)"),
        "ui.quickReport":    ("デジタル習慣レポート", "Digital habit report"),
        "ui.quickSettings":  ("設定", "Settings"),
        "ui.quickQuit":      ("Conscioを終了", "Quit Conscio"),
        "report.title":      ("Conscio デジタル習慣レポート", "Conscio Digital Habit Report"),
        "report.subtitle":   ("今週の作業リズムとディープワークの分析", "Your weekly rhythm & deep-work analysis"),
        "report.totalFocus": ("総ディープワーク時間", "Total deep-work time"),
        "report.praise":     ("素晴らしい集中力です！", "Wonderful focus!"),
        "report.chart7":     ("直近7日の集中時間 (分)", "Focus time, last 7 days (min)"),
        "report.switches":   ("文脈切り替え回数", "Context switches"),
        "report.steady":     ("非常に安定しています", "Very steady"),
        "report.scattered":  ("少し散漫かもしれません", "A bit scattered"),
        "report.topApps":    ("最も活用したアプリケーション", "Most used applications"),
        "report.noData":     ("まだ利用データが集計されていません。作業を継続すると表示されます。", "No data yet — keep working and this will fill in."),
    ]

    /// キーに対応する現在言語の文言を返す (未登録キーはキーそのもの返し=壊れない)
    static func t(_ key: String) -> String {
        guard let entry = table[key] else { return key }
        return isJapanese ? entry.ja : entry.en
    }
}
