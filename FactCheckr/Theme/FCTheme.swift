import SwiftUI

enum FCTheme {
    // MARK: - Colors (factcheckrai.com :root)
    static let bgPrimary = Color(hex: 0x0A0A0F)
    static let bgSecondary = Color(hex: 0x111118)
    static let bgCard = Color(hex: 0x16161F)
    static let bgCardHover = Color(hex: 0x1C1C28)

    static let accent = Color(hex: 0x6C5CE7)
    static let accentLight = Color(hex: 0xA29BFE)
    static let green = Color(hex: 0x00D2A0)
    static let red = Color(hex: 0xFF6B6B)
    static let orange = Color(hex: 0xFFA502)

    static let textPrimary = Color(hex: 0xE8E6F0)
    static let textSecondary = Color(hex: 0x9896A6)
    static let textMuted = Color(hex: 0x6B6980)

    static let border = Color.white.opacity(0.06)
    static let borderLight = Color.white.opacity(0.10)

    static let youtube = Color.red
    static let tiktok = Color(hex: 0xFF0050)
    static let tiktokCyan = Color(hex: 0x00F2EA)

    static let radiusSM: CGFloat = 10
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 20

    static func scoreColor(for score: Int?) -> Color {
        guard let score else { return textMuted }
        if score >= 70 { return green }
        if score >= 50 { return orange }
        return red
    }

    static func endpointColor(_ endpoint: AnalyzeEndpoint) -> Color {
        switch endpoint {
        case .article: return accentLight
        case .youtube: return youtube
        case .tiktok: return tiktok
        }
    }

    static func endpointIcon(_ endpoint: AnalyzeEndpoint) -> String {
        switch endpoint {
        case .article: return "doc.text.fill"
        case .youtube: return "play.rectangle.fill"
        case .tiktok: return "music.note"
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct FCBackground: View {
    var body: some View {
        ZStack {
            FCTheme.bgPrimary.ignoresSafeArea()
            Circle()
                .fill(FCTheme.accent.opacity(0.12))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: -80, y: -220)
            Circle()
                .fill(FCTheme.green.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 140, y: 280)
        }
    }
}
