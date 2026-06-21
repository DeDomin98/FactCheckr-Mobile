import Foundation

@MainActor
final class ShareLinkHandler: ObservableObject {
    @Published private(set) var pendingURL: String?

    func handleIncomingURL(_ url: URL) {
        guard ShareDeepLink.isAppOpenURL(url) else { return }
        adoptFromAppGroupIfAvailable()
    }

    func loadFromAppGroupIfNeeded() {
        guard pendingURL == nil else { return }
        adoptFromAppGroupIfAvailable()
    }

    func clearPending() {
        pendingURL = nil
        SharedLinkStore.clearPendingURL()
    }

    private func adoptFromAppGroupIfAvailable() {
        guard pendingURL == nil, let url = SharedLinkStore.consumePendingURL() else { return }
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pendingURL = trimmed
    }
}
