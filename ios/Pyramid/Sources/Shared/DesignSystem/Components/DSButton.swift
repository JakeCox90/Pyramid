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
        case .large:  return Theme.Typography.headline
        case .medium: return Theme.Typography.subheadline
        case .small:  return Theme.Typography.footnote
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .large:  return Theme.Spacing.s40
        case .medium: return Theme.Spacing.s30
        case .small:  return Theme.Spacing.s20
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
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.default))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.default)
                .strokeBorder(borderColor, lineWidth: variant == .secondary ? 1.5 : 0)
        )
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundColor(pressed: Bool) -> Color {
        switch variant {
        case .primary:
            return pressed ? Theme.Color.Primary.pressed : Theme.Color.Primary.resting
        case .secondary:
            return pressed ? Theme.Color.Surface.Background.page : .clear
        case .destructive:
            return pressed ? Theme.Color.Status.Error.resting.opacity(0.85) : Theme.Color.Status.Error.resting
        case .ghost:
            return pressed ? Theme.Color.Surface.Background.page : .clear
        }
    }

    private func foregroundColor(pressed: Bool) -> Color {
        switch variant {
        case .primary:     return Theme.Color.Surface.Background.container
        case .secondary:   return Theme.Color.Primary.resting
        case .destructive: return Theme.Color.Surface.Background.container
        case .ghost:       return Theme.Color.Primary.resting
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: return Theme.Color.Primary.resting
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
