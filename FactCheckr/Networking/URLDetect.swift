import Foundation

func isTikTokURL(_ url: String) -> Bool {
    let pattern = #"^https?://(www\.|vt\.|vm\.|m\.)?tiktok\.com/.+$"#
    return url.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
}

func isYouTubeURL(_ url: String) -> Bool {
    let pattern = #"^https?://(www\.)?(youtube\.com|youtu\.be)/.+$"#
    return url.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
}

enum AnalyzeEndpoint {
    case tiktok
    case youtube
    case article

    var path: String {
        switch self {
        case .tiktok: return "/api/analyze/tiktok"
        case .youtube: return "/api/analyze/youtube"
        case .article: return "/api/analyze"
        }
    }

    var label: String {
        switch self {
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        case .article: return "Artykuł"
        }
    }
}

func pickEndpoint(_ url: String) -> AnalyzeEndpoint {
    let u = url.trimmingCharacters(in: .whitespacesAndNewlines)
    if isTikTokURL(u) { return .tiktok }
    if isYouTubeURL(u) { return .youtube }
    return .article
}

func extractURL(from raw: String) -> String? {
    guard let m = raw.range(of: #"https?://[^\s]+"#, options: .regularExpression) else { return nil }
    return String(raw[m]).trimmingCharacters(in: CharacterSet(charactersIn: ")]\"'"))
}
