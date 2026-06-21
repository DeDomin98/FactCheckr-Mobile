import SwiftUI

// MARK: - Typography & layout helpers

extension FCTheme {
    static func heading(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func statValue() -> Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }

    static func labelCaps() -> Font {
        .system(size: 12, weight: .semibold)
    }

    static func threatColor(_ level: ThreatLevel) -> Color {
        switch level {
        case .none: return green
        case .medium: return orange
        case .high: return Color(hex: 0xE74C3C)
        }
    }
}

struct FCAppNavBar: View {
    var showLogout: Bool = false
    var onLogout: (() -> Void)?

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                FCLogo(size: 32)
                Text(AppMetadata.displayName)
                    .font(FCTheme.heading(18))
                    .foregroundStyle(FCTheme.textPrimary)
            }
            Spacer()
            if showLogout, let onLogout {
                Button(action: onLogout) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body.weight(.medium))
                        .foregroundStyle(FCTheme.textSecondary)
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Wyloguj")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct FCWelcomeCard: View {
    let name: String
    let planLabel: String
    var avatarLetter: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(FCTheme.accent.opacity(0.15))
                    .frame(width: 64, height: 64)
                Text(avatarLetter.uppercased())
                    .font(FCTheme.heading(22))
                    .foregroundStyle(FCTheme.accentLight)
            }
            .overlay(
                Circle().stroke(FCTheme.accent, lineWidth: 3)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Cześć, \(name)!")
                    .font(FCTheme.heading(20))
                    .foregroundStyle(FCTheme.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                    Text("\(planLabel) Plan")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(FCTheme.accentLight)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(FCTheme.accent.opacity(0.12))
                .overlay(Capsule().stroke(FCTheme.accent.opacity(0.25), lineWidth: 1))
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(20)
        .background(FCTheme.bgCard)
        .overlay(FCTopAccentLine())
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
    }
}

struct FCTopAccentLine: View {
    var body: some View {
        VStack {
            LinearGradient(
                colors: [FCTheme.accent, FCTheme.green],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
    }
}

struct FCDashStatCard: View {
    let icon: String
    let iconStyle: DashIconStyle
    let label: String
    let value: String
    var hint: String?
    var tokenPercent: Double?

    enum DashIconStyle {
        case accent, analyses, plan, account

        var colors: (bg: Color, fg: Color) {
            switch self {
            case .accent: return (FCTheme.accent.opacity(0.25), FCTheme.accentLight)
            case .analyses: return (FCTheme.green.opacity(0.2), FCTheme.green)
            case .plan: return (FCTheme.orange.opacity(0.15), FCTheme.orange)
            case .account: return (FCTheme.red.opacity(0.12), FCTheme.red)
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconStyle.colors.bg)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconStyle.colors.fg)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(FCTheme.labelCaps())
                    .foregroundStyle(FCTheme.textMuted)
                    .tracking(0.8)
                Text(value)
                    .font(FCTheme.statValue())
                    .foregroundStyle(FCTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let tokenPercent {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.06))
                            Capsule()
                                .fill(LinearGradient(colors: [FCTheme.accent, FCTheme.green], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * tokenPercent)
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 4)
                }
                if let hint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textMuted)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FCTheme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct FCScoreCircle: View {
    let score: Int?
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(FCTheme.scoreColor(for: score).opacity(0.2), lineWidth: 4)
            Text(score.map(String.init) ?? "—")
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .foregroundStyle(FCTheme.scoreColor(for: score))
        }
        .frame(width: size, height: size)
    }
}

struct FCReportChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(FCTheme.textMuted)
                .tracking(0.6)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FCTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(FCTheme.bgSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct FCSectionTitle: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(FCTheme.accentLight)
            Text(title)
                .font(FCTheme.heading(16))
                .foregroundStyle(FCTheme.textPrimary)
        }
    }
}

struct FCTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selection == tab ? .semibold : .regular))
                        Text(tab.title)
                            .font(.caption2.weight(selection == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selection == tab ? FCTheme.accentLight : FCTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            FCTheme.bgSecondary
                .overlay(Rectangle().frame(height: 1).foregroundStyle(FCTheme.border), alignment: .top)
        )
    }
}

struct FCHistoryRow: View {
    let entry: AnalysisHistoryEntry
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(FCTheme.threatColor(entry.threatLevel))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(entry.overallScore)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FCTheme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 8) {
                            Text(entry.type)
                            Text("·")
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(.caption2)
                        .foregroundStyle(FCTheme.textMuted)
                        if let verdict = entry.verdict {
                            Text(verdict)
                                .font(.caption)
                                .foregroundStyle(FCTheme.accentLight)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FCTheme.textMuted)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ReportDetailView(response: entry.response, sourceUrl: entry.sourceUrl)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
        }
        .background(FCTheme.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(isExpanded ? FCTheme.accent.opacity(0.35) : FCTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }
}

struct FCFilterPills: View {
    @Binding var selection: ThreatFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ThreatFilter.allCases, id: \.self) { filter in
                    Button {
                        selection = filter
                    } label: {
                        Text(filter.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selection == filter ? FCTheme.accentLight : FCTheme.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selection == filter ? FCTheme.accent.opacity(0.15) : Color.clear)
                            .overlay(
                                Capsule().stroke(selection == filter ? FCTheme.accent.opacity(0.4) : FCTheme.border, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct FCQuickAction: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FCTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .foregroundStyle(FCTheme.accentLight)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FCTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(FCTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
            .padding(14)
            .background(FCTheme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                    .stroke(FCTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct FCEmailBanner: View {
    var onVerify: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.badge.fill")
                .foregroundStyle(Color(hex: 0xFFB347))
            VStack(alignment: .leading, spacing: 2) {
                Text("Potwierdź e-mail")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FCTheme.textPrimary)
                Text("Analizy zablokowane do weryfikacji")
                    .font(.caption)
                    .foregroundStyle(FCTheme.textMuted)
            }
            Spacer()
            Button("Weryfikuj", action: onVerify)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: 0xFFD099))
        }
        .padding(14)
        .background(Color(hex: 0xFFB347).opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(Color(hex: 0xFFB347).opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }
}
