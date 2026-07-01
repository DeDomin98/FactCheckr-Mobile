import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var shareLinkHandler: ShareLinkHandler
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var analyzeViewModel = AnalyzeViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var path = NavigationPath()
    @State private var showOnboarding = !OnboardingStore.hasSeen
    @State private var showAuthGate = false
    @State private var showLogoutConfirm = false
    @State private var sharedURLToAnalyze: String?
    @State private var historyRefreshToken = 0
    @State private var showPostLoginTutorial = false
    @State private var isBootstrapping = true

    var body: some View {
        ZStack {
            Group {
                if showOnboarding {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showOnboarding = false
                        }
                        reconcileAuthGate()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else if showAuthGate {
                    AuthView(authViewModel: authViewModel, authManager: authManager) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAuthGate = false
                        }
                        requestPermissionsAfterLogin()
                        checkPostLoginTutorial()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    mainShell
                        .transition(.opacity)
                }
            }

            if isBootstrapping {
                SplashBootstrapView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showOnboarding)
        .animation(.easeInOut(duration: 0.35), value: showAuthGate)
        .animation(.easeOut(duration: 0.45), value: isBootstrapping)
        .onAppear {
            bootstrapIfNeeded()
            reconcileAuthGate()
            shareLinkHandler.loadFromAppGroupIfNeeded()
            handlePendingSharedLink()
            Task {
                await authManager.refreshSharedToken()
                await dashboardViewModel.refresh(authManager: authManager)
                await handleNotificationDeepLink()
            }
        }
        .onChange(of: authManager.isLoggedIn) { loggedIn in
            if loggedIn {
                reconcileAuthGate()
            }
            if loggedIn && !showOnboarding && !showAuthGate {
                requestPermissionsAfterLogin()
                checkPostLoginTutorial()
            }
            Task { await dashboardViewModel.refresh(authManager: authManager) }
        }
        .onChange(of: authManager.isAuthStateReady) { _ in
            reconcileAuthGate()
        }
        .onChange(of: shareLinkHandler.pendingURL) { _ in
            handlePendingSharedLink()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            shareLinkHandler.loadFromAppGroupIfNeeded()
            handlePendingSharedLink()
            Task {
                await authManager.refreshSharedToken()
                await dashboardViewModel.refresh(authManager: authManager)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fcOpenAnalysisResult)) { _ in
            Task {
                await dashboardViewModel.refresh(authManager: authManager)
                await handleNotificationDeepLink()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fcOpenPendingURL)) { _ in
            handlePendingSharedLink()
        }
    }

    private var mainShell: some View {
        ZStack(alignment: .bottom) {
            FCBackground()

            NavigationStack(path: $path) {
                VStack(spacing: 0) {
                    if path.isEmpty {
                        FCAppNavBar(
                            showLogout: authManager.isLoggedIn,
                            onLogout: { showLogoutConfirm = true }
                        )
                    }

                    tabContent
                }
                .navigationBarHidden(path.isEmpty)
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

            if path.isEmpty {
                FCTabBar(selection: $selectedTab)
            }
        }
        .confirmationDialog(Loc.t(.logoutConfirmTitle), isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button(Loc.t(.logout), role: .destructive) {
                try? authManager.signOut()
                showAuthGate = authManager.isConfigured
            }
            Button(Loc.t(.cancel), role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showPostLoginTutorial) {
            PostLoginTutorialView(analyzeViewModel: analyzeViewModel) { entry in
                completePostLoginTutorial(entry: entry)
            } onSkip: {
                completePostLoginTutorial(entry: nil)
            }
        }
        .onAppear {
            if authManager.isLoggedIn && !showOnboarding && !showAuthGate {
                requestPermissionsAfterLogin()
            }
        }
    }

    private func requestPermissionsAfterLogin() {
        guard authManager.isLoggedIn, !showOnboarding, !showAuthGate else { return }
        NotificationService.requestAuthorizationIfNeeded()
    }

    private func checkPostLoginTutorial() {
        Task {
            // ensureUserProfile (social sign-up) may still be writing the pending flag.
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard let uid = authManager.user?.uid,
                  PostLoginTutorialStore.shouldShow(for: uid) else { return }
            showPostLoginTutorial = true
        }
    }

    private func completePostLoginTutorial(entry: AnalysisHistoryEntry?) {
        if let uid = authManager.user?.uid {
            PostLoginTutorialStore.markSeen(for: uid)
        }
        showPostLoginTutorial = false
        analyzeViewModel.reset()
        if let entry {
            historyRefreshToken += 1
            homeViewModel.refreshRecent()
            path.append(AppRoute.result(entry))
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
                dashboardViewModel: dashboardViewModel,
                onResult: { entry in
                    historyRefreshToken += 1
                    path.append(AppRoute.result(entry))
                },
                onLoginRequired: {
                    if authManager.isLoggedIn {
                        Task { await authManager.refreshSharedToken() }
                    } else {
                        showAuthGate = true
                    }
                },
                onOpenAccount: { selectedTab = .account },
                sharedURLToAnalyze: $sharedURLToAnalyze
            )
        case .history:
            HistoryView(
                viewModel: dashboardViewModel,
                authManager: authManager,
                refreshToken: historyRefreshToken
            ) { entry in
                path.append(AppRoute.result(entry))
            }
        case .account:
            AccountView(
                authManager: authManager,
                viewModel: dashboardViewModel,
                onLogin: { showAuthGate = true },
                onVerifyEmail: { showAuthGate = true },
                onCheckLink: { selectedTab = .home },
                onAccountDeleted: {
                    showAuthGate = authManager.isConfigured
                    selectedTab = .home
                }
            )
        }
    }

    /// Closes the login sheet when a persisted session is restored. Never auto-opens it on launch.
    private func reconcileAuthGate() {
        guard authManager.isAuthStateReady else { return }
        if authManager.isLoggedIn {
            showAuthGate = false
        }
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

    private func bootstrapIfNeeded() {
        Task {
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            withAnimation(.easeOut(duration: 0.45)) {
                isBootstrapping = false
            }
        }
    }

    @MainActor
    private func handleNotificationDeepLink() async {
        guard !showOnboarding else { return }

        if let failedURL = NotificationDeepLinkStore.consumeFailedURL() {
            if showAuthGate {
                SharedLinkStore.savePendingURL(failedURL)
                return
            }
            selectedTab = .home
            sharedURLToAnalyze = failedURL
            return
        }

        guard let pending = NotificationDeepLinkStore.peekReady() else { return }

        if showAuthGate { return }

        guard let uid = authManager.user?.uid, pending.uid == uid else { return }

        await dashboardViewModel.refresh(authManager: authManager)

        var entry = dashboardViewModel.history.first(where: { $0.id == pending.entryId })
            ?? BackgroundAnalysisStore.peek(entryId: pending.entryId, uid: uid)

        if entry == nil, let sourceUrl = pending.sourceUrl {
            entry = BackgroundAnalysisStore.peek(sourceUrl: sourceUrl, uid: uid)
                ?? dashboardViewModel.history.first { urlsRoughlyMatch($0.sourceUrl, sourceUrl) }
        }

        guard let entry else { return }

        NotificationDeepLinkStore.clear()
        selectedTab = .home
        path.append(AppRoute.result(entry))
    }
}
