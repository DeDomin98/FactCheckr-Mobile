import SwiftUI

struct AccountView: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject private var localization: LocalizationManager
    var onLogin: () -> Void
    var onVerifyEmail: () -> Void
    var onCheckLink: () -> Void
    var onAccountDeleted: () -> Void = {}

    @State private var showDeleteConfirm = false
    @State private var showDeletePasswordSheet = false
    @State private var deletePassword = ""
    @State private var deleteError: String?
    @State private var isDeletingAccount = false

    private var profile: UserProfile? { viewModel.profile }

    private var planLabel: String {
        guard let profile else { return "FREE" }
        return profile.isTester ? "TESTER" : profile.plan.uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if authManager.isLoggedIn {
                    loggedInContent
                } else {
                    loggedOutContent
                }
                languageSection
                legalSection
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await viewModel.refresh(authManager: authManager) }
        .task { await viewModel.refresh(authManager: authManager) }
        .confirmationDialog(
            Loc.t(.deleteAccountTitle),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(Loc.t(.deleteAccountConfirm), role: .destructive) {
                beginDeleteFlow()
            }
            Button(Loc.t(.cancel), role: .cancel) {}
        } message: {
            Text(Loc.t(.deleteAccountMessage))
        }
        .sheet(isPresented: $showDeletePasswordSheet) {
            deletePasswordSheet
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                            .tint(FCTheme.accentLight)
                        Text(Loc.t(.deleteAccountDeleting))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FCTheme.textPrimary)
                    }
                    .padding(24)
                    .background(FCTheme.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private var loggedInContent: some View {
        if authManager.requiresEmailVerification {
            FCEmailBanner(onVerify: onVerifyEmail)
        }

        if let syncError = viewModel.syncError {
            Text(syncError)
                .font(.caption)
                .foregroundStyle(FCTheme.orange)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FCTheme.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
        }

        if let user = authManager.user {
            FCWelcomeCard(
                name: user.displayName ?? user.email?.components(separatedBy: "@").first ?? Loc.t(.userFallback),
                planLabel: planLabel,
                avatarLetter: String((user.displayName ?? user.email ?? "U").prefix(1))
            )
        }

        statsSection

        if viewModel.isLoading && profile == nil {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 8)
        }

        accountInfoCard

        FCSecondaryButton(title: Loc.t(.logout), icon: "rectangle.portrait.and.arrow.right") {
            try? authManager.signOut()
            Task { await viewModel.refresh(authManager: authManager) }
        }

        deleteAccountSection
    }

    private var deleteAccountSection: some View {
        FCCard {
            VStack(alignment: .leading, spacing: 12) {
                FCSectionTitle(icon: "exclamationmark.triangle.fill", title: Loc.t(.deleteAccount))
                Text(Loc.t(.deleteAccountMessage))
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)

                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text(Loc.t(.deleteAccountConfirm))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.red.opacity(0.95))
                    .background(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
                }
                .disabled(isDeletingAccount)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var deletePasswordSheet: some View {
        NavigationStack {
            ZStack {
                FCBackground()

                VStack(spacing: 20) {
                    Text(Loc.t(.deleteAccountPasswordPrompt))
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    FCTextField(
                        placeholder: Loc.t(.deleteAccountPasswordPlaceholder),
                        text: $deletePassword,
                        isSecure: true
                    )

                    if let deleteError {
                        Text(deleteError)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    FCPrimaryButton(title: Loc.t(.deleteAccountConfirm), icon: "trash.fill") {
                        Task { await performDelete(password: deletePassword) }
                    }
                    .disabled(deletePassword.isEmpty || isDeletingAccount)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle(Loc.t(.deleteAccount))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Loc.t(.cancel)) {
                        showDeletePasswordSheet = false
                        deletePassword = ""
                        deleteError = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var languageSection: some View {
        FCCard {
            VStack(alignment: .leading, spacing: 12) {
                FCSectionTitle(icon: "globe", title: Loc.t(.languageSection))
                Picker(Loc.t(.languageSection), selection: $localization.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                Text(Loc.t(.languageHint))
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var statsSection: some View {
        let locked = authManager.requiresEmailVerification
        VStack(spacing: 12) {
            FCDashStatCard(
                icon: "bolt.shield.fill",
                iconStyle: .accent,
                label: locked ? Loc.t(.analysesLocked) : (profile?.isTester == true ? Loc.t(.testerMonthlyLimit) : Loc.t(.remainingAnalyses)),
                value: locked ? "0" : "\(viewModel.quotaRemaining)",
                hint: locked ? Loc.t(.verifyToUnlock) : String(format: Loc.t(.ofAvailableFmt), viewModel.quotaLimit),
                tokenPercent: locked ? 0 : viewModel.quotaPercent
            )

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    FCDashStatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconStyle: .analyses,
                        label: Loc.t(.totalAnalysesLabel),
                        value: "\(profile?.totalAnalyses ?? viewModel.history.count)",
                        hint: Loc.t(.wholeHistory),
                        compactPair: true
                    )
                    FCDashStatCard(
                        icon: "crown.fill",
                        iconStyle: .plan,
                        label: Loc.t(.planLabelText),
                        value: planLabel.capitalized,
                        hint: profile?.isTester == true ? Loc.t(.testerAccess) : Loc.t(.earlyAccess),
                        compactPair: true
                    )
                }
            }
        }
    }

    private var accountInfoCard: some View {
        FCCard {
            VStack(alignment: .leading, spacing: 14) {
                FCSectionTitle(icon: "person.text.rectangle.fill", title: Loc.t(.yourAccount))
                if let user = authManager.user {
                    row(icon: "envelope.fill", title: Loc.t(.email), value: user.email ?? "—")
                    row(
                        icon: user.isEmailVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        title: Loc.t(.verification),
                        value: user.isEmailVerified ? Loc.t(.verified) : Loc.t(.pending)
                    )
                }
                row(icon: "number", title: Loc.t(.appVersion), value: AppMetadata.fullVersion)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var loggedOutContent: some View {
        VStack(spacing: 16) {
            FCLogo(size: 72, glow: true)
            Text(String(format: Loc.t(.joinFmt), AppMetadata.displayName))
                .font(FCTheme.heading(22))
                .foregroundStyle(FCTheme.textPrimary)
            Text(Loc.t(.loggedOutSub))
                .font(.subheadline)
                .foregroundStyle(FCTheme.textSecondary)
                .multilineTextAlignment(.center)

            FCPrimaryButton(title: Loc.t(.loginRegister), icon: "arrow.right") { onLogin() }
            FCSecondaryButton(title: Loc.t(.checkWithoutAccount), icon: "link") { onCheckLink() }
        }
        .padding(.vertical, 20)
    }

    private var legalSection: some View {
        FCCard {
            VStack(alignment: .leading, spacing: 10) {
                FCSectionTitle(icon: "hand.raised.fill", title: Loc.t(.privacy))
                Link(Loc.t(.privacyPolicy), destination: URL(string: APIConfig.privacyURL)!)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.accentLight)
                Text(Loc.t(.privacyText))
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var aboutSection: some View {
        FCCard {
            VStack(alignment: .leading, spacing: 10) {
                FCSectionTitle(icon: "info.circle.fill", title: Loc.t(.aboutApp))
                Text(String(format: Loc.t(.aboutText), AppMetadata.displayName))
                    .font(.caption)
                    .foregroundStyle(FCTheme.textSecondary)
                Link("factcheckrai.com", destination: URL(string: APIConfig.appURL)!)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FCTheme.accentLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(FCTheme.accentLight)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            Spacer()
        }
    }

    private func beginDeleteFlow() {
        deleteError = nil
        if authManager.usesEmailPasswordProvider {
            deletePassword = ""
            showDeletePasswordSheet = true
        } else {
            Task { await performDelete(password: nil) }
        }
    }

    @MainActor
    private func performDelete(password: String?) async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        deleteError = nil
        defer { isDeletingAccount = false }

        do {
            try await authManager.deleteAccount(password: password)
            showDeletePasswordSheet = false
            deletePassword = ""
            await viewModel.refresh(authManager: authManager)
            Haptics.notify(.success)
            onAccountDeleted()
        } catch {
            deleteError = error.localizedDescription
            Haptics.notify(.error)
        }
    }
}
