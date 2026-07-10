import SwiftUI
import UIKit

enum FCTheme {
    // MARK: - Adaptive colors (light + dark)

    static let bgPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1)   // #0A0A0F
            : UIColor(red: 0.965, green: 0.965, blue: 0.980, alpha: 1)   // #F6F6FA
    })

    static let bgSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.067, green: 0.067, blue: 0.094, alpha: 1)   // #111118
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    })

    static let bgCard = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.086, green: 0.086, blue: 0.122, alpha: 1)   // #16161F
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    })

    static let bgCardHover = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.110, green: 0.110, blue: 0.157, alpha: 1)   // #1C1C28
            : UIColor(red: 0.945, green: 0.945, blue: 0.965, alpha: 1)
    })

    static let accent = Color(hex: 0x6C5CE7)
    static let accentLight = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.635, green: 0.608, blue: 0.996, alpha: 1)   // #A29BFE
            : UIColor(red: 0.424, green: 0.361, blue: 0.906, alpha: 1)   // #6C5CE7
    })

    static let green = Color(hex: 0x00D2A0)
    static let red = Color(hex: 0xFF6B6B)
    static let orange = Color(hex: 0xFFA502)

    static let textPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.910, green: 0.902, blue: 0.941, alpha: 1)   // #E8E6F0
            : UIColor(red: 0.102, green: 0.102, blue: 0.141, alpha: 1)   // #1A1A24
    })

    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.596, green: 0.588, blue: 0.651, alpha: 1)   // #9896A6
            : UIColor(red: 0.420, green: 0.420, blue: 0.490, alpha: 1)
    })

    static let textMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.420, green: 0.412, blue: 0.502, alpha: 1)   // #6B6980
            : UIColor(red: 0.580, green: 0.580, blue: 0.640, alpha: 1)
    })

    static let border = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.06)
            : UIColor.black.withAlphaComponent(0.08)
    })

    static let borderLight = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.black.withAlphaComponent(0.12)
    })

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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            FCTheme.bgPrimary.ignoresSafeArea()
            Circle()
                .fill(FCTheme.accent.opacity(colorScheme == .dark ? 0.12 : 0.08))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: -80, y: -220)
            Circle()
                .fill(FCTheme.green.opacity(colorScheme == .dark ? 0.08 : 0.06))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 140, y: 280)
        }
    }
}
