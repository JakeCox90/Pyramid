import SwiftUI

// MARK: - Design System: Typography
// SF Pro — iOS system font. Matches Apple's Dynamic Type scale.
// Use .DS.font(...) everywhere. Never raw Font.system(...) in Views.

extension Font {
    enum DS {
        static let display      = Font.system(size: 34, weight: .bold)
        static let title1       = Font.system(size: 28, weight: .bold)
        static let title2       = Font.system(size: 22, weight: .semibold)
        static let title3       = Font.system(size: 20, weight: .semibold)
        static let headline     = Font.system(size: 17, weight: .semibold)
        static let body         = Font.system(size: 17, weight: .regular)
        static let callout      = Font.system(size: 16, weight: .regular)
        static let subheadline  = Font.system(size: 15, weight: .regular)
        static let footnote     = Font.system(size: 13, weight: .regular)
        static let caption1     = Font.system(size: 12, weight: .regular)
        static let caption2     = Font.system(size: 11, weight: .regular)
    }
}

// MARK: - View Modifier convenience

extension View {
    func dsFont(_ font: Font) -> some View {
        self.font(font)
    }
}
