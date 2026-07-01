import SwiftUI
import UIKit

/// Global navigation chrome — always uses the solid dark theme tab bar (no iOS 26 floating glass).
enum FCAdaptiveChrome {
    static func configureGlobalAppearance() {
        configureLegacyNavigationAppearance()
        UITabBar.appearance().isHidden = true
    }

    private static func configureLegacyNavigationAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(FCTheme.bgPrimary.opacity(0.98))
        nav.shadowColor = UIColor.black.withAlphaComponent(0.25)
        nav.titleTextAttributes = [
            .foregroundColor: UIColor(FCTheme.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(FCTheme.accentLight)
        UINavigationBar.appearance().layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(
            UIOffset(horizontal: 6, vertical: 0),
            for: .default
        )
    }
}

extension View {
    func fcFluidNavigationBar() -> some View {
        toolbarBackground(FCTheme.bgPrimary.opacity(0.98), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }

    func fcFloatingTabBarBackground() -> some View {
        padding(.horizontal, 8)
            .padding(.top, 8)
            .background(
                FCTheme.bgSecondary
                    .overlay(Rectangle().frame(height: 1).foregroundStyle(FCTheme.border), alignment: .top)
                    .ignoresSafeArea(edges: .bottom)
            )
    }
}
