import SwiftUI

@main
struct FactCheckrApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var shareLinkHandler = ShareLinkHandler()

    init() {
        configureFirebaseIfPossible()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(authManager)
                .environmentObject(shareLinkHandler)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    shareLinkHandler.handleIncomingURL(url)
                }
        }
    }

    private func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = UIColor(FCTheme.bgPrimary.opacity(0.95))
        nav.titleTextAttributes = [.foregroundColor: UIColor(FCTheme.textPrimary)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(FCTheme.accentLight)
        UITabBar.appearance().isHidden = true
    }
}
