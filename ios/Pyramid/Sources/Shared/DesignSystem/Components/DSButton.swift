import SwiftUI

// MARK: - DS Button Style

enum DSButtonVariant {
    case primary, secondary, destructive, ghost
}

enum DSButtonSize {
    case large, medium, small

    var height: CGFloat {
        switch self {
        case .large:  return 50
        case .medium: return 40
        case .small:  return 32
        }
    }

    var font: Font {
        switch self {
        case .large:  return .DS.headline
        case .medium: return .DS.subheadline
        case .small:  return .DS.footnote
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .large:  return DS.Spacing.s4
        case .medium: return DS.Spacing.s3
        case .small:  return DS.Spacing.s2
        }
    }
}

struct DSButtonStyle: ButtonStyle {
    let variant: DSButtonVariant
    let size: DSButtonSize
    var isLoading: Bool = false
    var isFullWidth: Bool = true

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .tint(foregroundColor(pressed: false))
            } else {
                configuration.label
                    .font(size.font)
                    .foregroundStyle(foregroundColor(pressed: configuration.isPressed))
            }
        }
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .frame(height: size.height)
        .padding(.horizontal, isFullWidth ? 0 : size.horizontalPadding)
        .background(backgroundColor(pressed: configuration.isPressed))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .strokeBorder(borderColor, lineWidth: variant == .secondary ? 1.5 : 0)
        )
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundColor(pressed: Bool) -> Color {
        switch variant {
        case .primary:
            return pressed ? .DS.Brand.primaryHover : .DS.Brand.primary
        case .secondary:
            return pressed ? .DS.Neutral.n100 : .clear
        case .destructive:
            return pressed ? Color.DS.Semantic.error.opacity(0.85) : .DS.Semantic.error
        case .ghost:
            return pressed ? .DS.Neutral.n100 : .clear
        }
    }

    private func foregroundColor(pressed: Bool) -> Color {
        switch variant {
        case .primary:     return .DS.Neutral.n000
        case .secondary:   return .DS.Brand.primary
        case .destructive: return .DS.Neutral.n000
        case .ghost:       return .DS.Brand.primary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: return .DS.Brand.primary
        default:         return .clear
        }
    }
}

// MARK: - Convenience modifier

extension Button {
    func dsStyle(
        _ variant: DSButtonVariant = .primary,
        size: DSButtonSize = .large,
        isLoading: Bool = false,
        fullWidth: Bool = true
    ) -> some View {
        self.buttonStyle(
            DSButtonStyle(variant: variant, size: size, isLoading: isLoading, isFullWidth: fullWidth)
        )
    }
}
