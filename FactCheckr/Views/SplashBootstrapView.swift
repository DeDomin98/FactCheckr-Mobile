import SwiftUI

/// Brief branded splash shown on cold start while the app settles auth / routing.
struct SplashBootstrapView: View {
    @State private var logoScale: CGFloat = 0.82
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            FCTheme.bgPrimary.ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [FCTheme.accent.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(y: -40)
                .blur(radius: 8)

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    FCTheme.accent.opacity(0.05),
                                    FCTheme.accentLight.opacity(0.55),
                                    FCTheme.green.opacity(0.35),
                                    FCTheme.accent.opacity(0.05)
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(ringRotation))

                    FCLogo(size: 72, glow: true)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 10) {
                    Text(AppMetadata.displayName)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(FCTheme.textPrimary)
                        .tracking(0.3)

                    Text(Loc.t(.splashTagline))
                        .font(.subheadline)
                        .foregroundStyle(FCTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }
                .opacity(logoOpacity)

                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [FCTheme.accent, FCTheme.accentLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(12, geo.size.width * progress))
                        }
                    }
                    .frame(height: 3)
                    .frame(maxWidth: 160)

                    Text(Loc.t(.splashLoading))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(FCTheme.textMuted)
                }
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
                logoScale = 1
                logoOpacity = 1
            }
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 1.1)) {
                progress = 0.92
            }
        }
    }
}
