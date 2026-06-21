import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var shareLinkHandler: ShareLinkHandler
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var analyzeViewModel = AnalyzeViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var path = NavigationPath()
    @State private var showOnboarding = !OnboardingStore.hasSeen
    @State private var showAuthGate = false
    @State private var showLogoutConfirm = false
    @State private var sharedURLToAnalyze: String?
    @State private var historyRefreshToken = 0

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                    updateAuthGate()
                }
            } else if showAuthGate {
                AuthView(authViewModel: authViewModel, authManager: authManager) {
                    showAuthGate = false
                }
            } else {
                mainShell
            }
        }
        .onAppear {
            updateAuthGate()
            shareLinkHandler.loadFromAppGroupIfNeeded()
            handlePendingSharedLink()
        }
        .onChange(of: authManager.isLoggedIn) { _ in
            if !showOnboarding { updateAuthGate() }
        }
        .onChange(of: shareLinkHandler.pendingURL) { _ in
            handlePendingSharedLink()
        }
    }

    private var mainShell: some View {
        ZStack(alignment: .bottom) {
            FCBackground()

            NavigationStack(path: $path) {
                VStack(spacing: 0) {
                    FCAppNavBar(
                        showLogout: authManager.isLoggedIn,
                        onLogout: { showLogoutConfirm = true }
                    )

                    tabContent
                }
                .navigationBarHidden(true)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case let .result(entry):
                        ResultView(entry: entry) {
                            path = NavigationPath()
                            selectedTab = .home
                        }
                    }
                }
            }

            FCTabBar(selection: $selectedTab)
        }
        .confirmationDialog("Wylogować się?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Wyloguj", role: .destructive) {
                try? authManager.signOut()
                showAuthGate = authManager.isConfigured
            }
            Button("Anuluj", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView(
                homeViewModel: homeViewModel,
                analyzeViewModel: analyzeViewModel,
                authManager: authManager,
                onResult: { entry in
                    historyRefreshToken += 1
                    path.append(AppRoute.result(entry))
                },
                onLoginRequired: {
                    showAuthGate = true
                },
                sharedURLToAnalyze: $sharedURLToAnalyze
            )
        case .history:
            HistoryView(refreshToken: historyRefreshToken) { entry in
                path.append(AppRoute.result(entry))
            }
        }
    }

    private func updateAuthGate() {
        showAuthGate = authManager.isConfigured && !authManager.isLoggedIn
    }

    private func handlePendingSharedLink() {
        guard let url = shareLinkHandler.pendingURL else { return }
        selectedTab = .home
        shareLinkHandler.clearPending()
        if showOnboarding || showAuthGate {
            homeViewModel.urlText = url
        } else {
            sharedURLToAnalyze = url
        }
    }
}
