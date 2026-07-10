import SwiftUI

@main
struct FactCheckrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var shareLinkHandler = ShareLinkHandler()
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureFirebaseIfPossible()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(authManager)
                .environmentObject(shareLinkHandler)
                .environmentObject(localization)
                .environment(\.locale, Locale(identifier: localization.code))
                .environmentObject(NetworkMonitor.shared)
                .id(localization.language)
                .onOpenURL { url in
                    if authManager.handleURL(url) { return }
                    shareLinkHandler.handleIncomingURL(url)
                }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                Task { await authManager.refreshSharedToken() }
                shareLinkHandler.loadFromAppGroupIfNeeded()
                BackgroundAnalysisService.shared.activate()
            case .inactive, .background:
                Task { await authManager.refreshSharedToken() }
            default:
                break
            }
        }
    }

    private func configureAppearance() {
        FCAdaptiveChrome.configureGlobalAppearance()
    }
}
