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
                    AuthView(
                        authViewModel: authViewModel,
                        authManager: authManager,
                        onAuthenticated: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAuthGate = false
                            }
                            requestPermissionsAfterLogin()
                            checkPostLoginTutorial()
                        },
                        onContinueAsGuest: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAuthGate = false
                            }
                        }
                    )
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
                await handleNotificationDeepLink()
                // Resume Live Activity UI for any still-running background jobs.
                if let uid = authManager.user?.uid {
                    for url in BackgroundInflightStore.allInflight(uid: uid) {
                        AnalysisLiveActivityController.ensureForInflight(url: url, endpoint: pickEndpoint(url))
                    }
                }
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
                // Stay in the main shell as guest — don't trap behind auth.
                showAuthGate = false
                selectedTab = .home
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
            for _ in 0..<8 {
                if let uid = authManager.user?.uid,
                   PostLoginTutorialStore.shouldShow(for: uid) {
                    showPostLoginTutorial = true
                    return
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
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
                    showAuthGate = false
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
            // Wait for auth restore, with a short floor so the splash doesn't flash.
            let started = Date()
            while !authManager.isAuthStateReady {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Date().timeIntervalSince(started) > 2.0 { break }
            }
            let elapsed = Date().timeIntervalSince(started)
            if elapsed < 0.45 {
                try? await Task.sleep(nanoseconds: UInt64((0.45 - elapsed) * 1_000_000_000))
            }
            withAnimation(.easeOut(duration: 0.35)) {
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

        if showAuthGate {
            // Keep pending until the user finishes auth / continues as guest.
            return
        }

        // Wait briefly for auth restore if the app was cold-started from a notification.
        if !authManager.isAuthStateReady {
            for _ in 0..<20 {
                if authManager.isAuthStateReady { break }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }

        guard let uid = authManager.user?.uid else {
            // Not logged in — keep the deep link and open auth so the user can continue.
            showAuthGate = authManager.isConfigured
            return
        }

        guard pending.uid == uid else {
            // Wrong account — clear stale payload to avoid a loop.
            NotificationDeepLinkStore.clear()
            return
        }

        await dashboardViewModel.refresh(authManager: authManager)

        var entry = dashboardViewModel.history.first(where: { $0.id == pending.entryId })
            ?? BackgroundAnalysisStore.peek(entryId: pending.entryId, uid: uid)

        if entry == nil, let sourceUrl = pending.sourceUrl {
            entry = BackgroundAnalysisStore.peek(sourceUrl: sourceUrl, uid: uid)
                ?? dashboardViewModel.history.first { urlsRoughlyMatch($0.sourceUrl, sourceUrl) }
        }

        // One short retry — background store may still be writing.
        if entry == nil {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await dashboardViewModel.refresh(authManager: authManager)
            entry = dashboardViewModel.history.first(where: { $0.id == pending.entryId })
            if entry == nil, let sourceUrl = pending.sourceUrl {
                entry = BackgroundAnalysisStore.peek(sourceUrl: sourceUrl, uid: uid)
                    ?? dashboardViewModel.history.first { urlsRoughlyMatch($0.sourceUrl, sourceUrl) }
            }
        }

        guard let entry else {
            // Don't clear — user can pull-to-refresh history; surface a hint via pending URL.
            if let sourceUrl = pending.sourceUrl {
                selectedTab = .home
                sharedURLToAnalyze = sourceUrl
            }
            return
        }

        NotificationDeepLinkStore.clear()
        AnalysisLiveActivityController.complete(
            url: entry.sourceUrl,
            success: true,
            message: Loc.t(.liveActivityDone)
        )
        selectedTab = .home
        path.append(AppRoute.result(entry))
    }
}
