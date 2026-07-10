import SwiftUI

struct FCLogo: View {
    var size: CGFloat = 36
    /// When true a subtle glow is drawn behind the shield (used on hero/auth screens).
    var glow: Bool = false

    var body: some View {
        Image("AppLogo")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .shadow(color: glow ? FCTheme.accent.opacity(0.45) : .clear,
                    radius: glow ? size * 0.22 : 0)
    }
}

struct FCBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(FCTheme.green)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(FCTheme.accentLight)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(FCTheme.accent.opacity(0.12))
        .overlay(
            Capsule().stroke(FCTheme.accent.opacity(0.25), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct FCStatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(FCTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(FCTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FCCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(FCTheme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous)
                    .stroke(FCTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusLG, style: .continuous))
    }
}

struct FCPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading = false
    var disabled = false
    var gradient: [Color] = [FCTheme.accent, Color(hex: 0x5B4BD4)]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
            .opacity(disabled ? 0.45 : 1)
        }
        .disabled(disabled || isLoading)
    }
}

struct FCSecondaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(FCTheme.textPrimary)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(FCTheme.textPrimary)
            .background(Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                    .stroke(FCTheme.borderLight, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
            .opacity(isLoading ? 0.7 : 1)
        }
        .disabled(isLoading)
    }
}

struct FCTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var isSecure = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text, axis: axis)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(14)
        .foregroundStyle(FCTheme.textPrimary)
        .background(FCTheme.bgPrimary)
        .overlay(
            RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous)
                .stroke(FCTheme.borderLight, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusMD, style: .continuous))
    }
}

struct FCEndpointTabs: View {
    @Binding var selection: AnalyzeEndpoint

    var body: some View {
        HStack(spacing: 8) {
            ForEach([AnalyzeEndpoint.article, .youtube, .tiktok], id: \.label) { endpoint in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = endpoint }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: FCTheme.endpointIcon(endpoint))
                            .font(.caption)
                        Text(endpoint.localizedLabel)
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selection == endpoint ? activeColor(endpoint) : FCTheme.textMuted)
                    .background(selection == endpoint ? activeBackground(endpoint) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous)
                            .stroke(selection == endpoint ? activeColor(endpoint).opacity(0.5) : FCTheme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: FCTheme.radiusSM, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func activeColor(_ endpoint: AnalyzeEndpoint) -> Color {
        FCTheme.endpointColor(endpoint)
    }

    private func activeBackground(_ endpoint: AnalyzeEndpoint) -> Color {
        switch endpoint {
        case .article: return FCTheme.accent.opacity(0.12)
        case .youtube: return Color.red.opacity(0.08)
        case .tiktok: return FCTheme.tiktok.opacity(0.10)
        }
    }
}

struct FCStageStep: View {
    let stage: AnalysisStage
    let isActive: Bool
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(isDone || isActive ? FCTheme.accent : FCTheme.borderLight, lineWidth: 2)
                    .frame(width: 28, height: 28)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundStyle(FCTheme.green)
                } else if isActive {
                    Circle()
                        .fill(FCTheme.accent)
                        .frame(width: 10, height: 10)
                }
            }
            Text(stage.displayName)
                .font(.subheadline.weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? FCTheme.textPrimary : FCTheme.textMuted)
            Spacer()
        }
    }
}

struct FCGradientTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [FCTheme.accentLight, FCTheme.green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .multilineTextAlignment(.center)
    }
}
