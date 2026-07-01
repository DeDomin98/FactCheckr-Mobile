import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var urlText = ""
    @Published var recentEntries: [AnalysisHistoryEntry] = []
    @Published private(set) var clipboardTikTokURL: String?

    var extractedURL: String? {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return extractURL(from: trimmed) ?? trimmed
    }

    var canSubmit: Bool {
        guard let url = extractedURL else { return false }
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }

    var urlValidationError: String? {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard canSubmit else {
            return Loc.t(.invalidUrl)
        }
        return nil
    }

    func refreshRecent() {
        recentEntries = Array(AnalysisHistoryStore.shared.load().prefix(3))
    }

    func refreshClipboardTikTokURL() {
        #if os(iOS)
        clipboardTikTokURL = Self.detectTikTokURLInClipboard()
        #else
        clipboardTikTokURL = nil
        #endif
    }

    func pasteFromClipboard() {
        #if os(iOS)
        if let str = UIPasteboard.general.string {
            urlText = str
            clipboardTikTokURL = nil
        }
        #endif
    }

    func applyClipboardTikTokURL() {
        guard let url = clipboardTikTokURL else {
            pasteFromClipboard()
            return
        }
        urlText = url
        clipboardTikTokURL = nil
    }

    func clearClipboardHint() {
        clipboardTikTokURL = nil
    }

    func clearInput() {
        urlText = ""
    }

    #if os(iOS)
    private static func detectTikTokURLInClipboard() -> String? {
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasStrings, let text = pasteboard.string else { return nil }
        guard let url = extractURL(from: text), isTikTokURL(url) else { return nil }
        return url
    }
    #endif
}
