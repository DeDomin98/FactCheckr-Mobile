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
                .id(localization.language)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    if authManager.handleURL(url) { return }
                    shareLinkHandler.handleIncomingURL(url)
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                // Keep a fresh ID token in the App Group so the share extension can
                // analyze in the background, and pick up any shared links.
                Task { await authManager.refreshSharedToken() }
                shareLinkHandler.loadFromAppGroupIfNeeded()
            }
        }
    }

    private func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(FCTheme.bgPrimary.opacity(0.98))
        nav.shadowColor = UIColor.black.withAlphaComponent(0.25)
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(FCTheme.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(FCTheme.accentLight)
        UINavigationBar.appearance().layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(
            UIOffset(horizontal: 6, vertical: 0),
            for: .default
        )
        UITabBar.appearance().isHidden = true
    }
}
