import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var authManager: AuthManager
    var onCheckLink: () -> Void
    var onVerifyEmail: () -> Void
    var onLogin: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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

                if authManager.isLoggedIn, let profile = viewModel.profile {
                    FCWelcomeCard(
                        name: profile.displayName ?? profile.email ?? "Użytkowniku",
                        planLabel: profile.isTester ? "TESTER" : profile.plan.uppercased(),
                        avatarLetter: String((profile.displayName ?? profile.email ?? "U").prefix(1))
                    )

                    statsGrid(profile: profile)
                } else {
                    guestWelcome
                }

                historySection

                VStack(spacing: 10) {
                    FCSectionTitle(icon: "bolt.fill", title: "Szybkie akcje")
                    FCQuickAction(
                        icon: "link.badge.plus",
                        title: "Sprawdź link",
                        subtitle: "Wklej URL TikTok, YouTube lub artykułu"
                    ) { onCheckLink() }

                    if !authManager.isLoggedIn {
                        FCQuickAction(
                            icon: "person.badge.plus",
                            title: "Utwórz konto",
                            subtitle: "5 darmowych analiz po rejestracji"
                        ) { onLogin() }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .refreshable {
            await viewModel.refresh(authManager: authManager)
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            await viewModel.refresh(authManager: authManager)
        }
    }

    private var guestWelcome: some View {
        VStack(alignment: .leading, spacing: 12) {
            FCWelcomeCard(
                name: "Gościu",
                planLabel: "EARLY ACCESS",
                avatarLetter: "G"
            )
            Text("Zaloguj się, aby synchronizować historię z kontem i otrzymać 5 analiz.")
                .font(.caption)
                .foregroundStyle(FCTheme.textSecondary)
        }
    }

    @ViewBuilder
    private func statsGrid(profile: UserProfile) -> some View {
        let locked = authManager.requiresEmailVerification
        VStack(spacing: 12) {
            FCDashStatCard(
                icon: "bitcoinsign.circle.fill",
                iconStyle: .accent,
                label: locked ? "Analizy zablokowane" : (profile.isTester ? "Miesięczny limit testera" : "Darmowe tokeny"),
                value: locked ? "0" : "\(viewModel.quotaRemaining)",
                hint: locked ? "Potwierdź e-mail, aby odblokować" : "Pozostało w tym okresie",
                tokenPercent: locked ? 0 : viewModel.quotaPercent
            )

            HStack(spacing: 12) {
                FCDashStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconStyle: .analyses,
                    label: "Łącznie analiz",
                    value: "\(profile.totalAnalyses)",
                    hint: "cała historia"
                )
                FCDashStatCard(
                    icon: "shield.lefthalf.filled",
                    iconStyle: .account,
                    label: "Konto",
                    value: profile.email?.components(separatedBy: "@").first ?? "—",
                    hint: profile.isTester ? "Dostęp testera" : "Early access"
                )
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                FCSectionTitle(icon: "clock.arrow.circlepath", title: "Historia analiz")
                Spacer()
                if !viewModel.history.isEmpty {
                    Text("\(viewModel.filteredHistory.count)/\(viewModel.history.count)")
                        .font(.caption)
                        .foregroundStyle(FCTheme.textMuted)
                    Menu {
                        Button("Wyczyść historię lokalną", role: .destructive) {
                            viewModel.clearLocalHistory()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(FCTheme.textMuted)
                    }
                }
            }

            if !viewModel.history.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(FCTheme.textMuted)
                    TextField("Szukaj po URL, werdykcie…", text: $viewModel.searchQuery)
                        .foregroundStyle(FCTheme.textPrimary)
                }
                .padding(12)
                .background(FCTheme.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                        .stroke(FCTheme.borderLight, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))

                FCFilterPills(selection: $viewModel.threatFilter)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if viewModel.filteredHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(FCTheme.textMuted)
                    Text("Brak analiz. Sprawdź pierwszy link, aby zobaczyć wyniki tutaj.")
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    FCPrimaryButton(title: "Sprawdź link", icon: "link") { onCheckLink() }
                }
                .padding(.vertical, 24)
            } else {
                ForEach(viewModel.filteredHistory) { entry in
                    FCHistoryRow(
                        entry: entry,
                        isExpanded: viewModel.expandedId == entry.id
                    ) {
                        viewModel.toggleExpanded(entry.id)
                    }
                    .contextMenu {
                        Button("Usuń", role: .destructive) {
                            viewModel.deleteEntry(entry.id)
                        }
                    }
                }
            }
        }
    }
}
