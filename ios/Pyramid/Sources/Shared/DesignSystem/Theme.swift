import SwiftUI
import UIKit

// MARK: - Theme: Unified Design System Namespace
// All design tokens accessed via Theme.* — sourced from tokens/semantic/*.json

enum Theme {

    // MARK: - Adaptive Color Helpers

    static func color(light: String, dark: String) -> SwiftUI.Color {
        SwiftUI.Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? hexToUIColor(dark)
                : hexToUIColor(light)
        })
    }

    static func color(light: UIColor, dark: UIColor) -> SwiftUI.Color {
        SwiftUI.Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static func hexToUIColor(_ hex: String) -> UIColor {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }

    static func rgbaUIColor(
        _ red: CGFloat,
        _ green: CGFloat,
        _ blue: CGFloat,
        _ alpha: CGFloat
    ) -> UIColor {
        UIColor(
            red: red / 255,
            green: green / 255,
            blue: blue / 255,
            alpha: alpha
        )
    }
}
