import SwiftUI
import UIKit

/// Global navigation chrome that follows the current light/dark appearance.
enum FCAdaptiveChrome {
    static func configureGlobalAppearance() {
        configureNavigationAppearance()
        UITabBar.appearance().isHidden = true
    }

    private static func configureNavigationAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor { traits in
            let base = traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1)
                : UIColor(red: 0.965, green: 0.965, blue: 0.980, alpha: 1)
            return base.withAlphaComponent(0.98)
        }
        nav.shadowColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.25)
                : UIColor.black.withAlphaComponent(0.08)
        }
        nav.titleTextAttributes = [
            .foregroundColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.910, green: 0.902, blue: 0.941, alpha: 1)
                    : UIColor(red: 0.102, green: 0.102, blue: 0.141, alpha: 1)
            },
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.635, green: 0.608, blue: 0.996, alpha: 1)
                : UIColor(red: 0.424, green: 0.361, blue: 0.906, alpha: 1)
        }
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
