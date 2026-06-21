import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var urlText = ""
    @Published var recentEntries: [AnalysisHistoryEntry] = []

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
            return "Nieprawidłowy adres URL. Wklej link zaczynający się od https://"
        }
        return nil
    }

    func refreshRecent() {
        recentEntries = Array(AnalysisHistoryStore.shared.load().prefix(3))
    }

    func pasteFromClipboard() {
        #if os(iOS)
        if let str = UIPasteboard.general.string {
            urlText = str
        }
        #endif
    }

    func clearInput() {
        urlText = ""
    }
}
