import SwiftUI

// MARK: - DS Button Variant

enum ButtonVariant {
    case primary, secondary, destructive, ghost
}

// MARK: - DS Button Style

struct ButtonThemeStyle: ButtonStyle {
    let variant: ButtonVariant
    var isLoading: Bool = false
    var isFullWidth: Bool = true

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(
        configuration: Configuration
    ) -> some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .tint(foregroundColor)
            } else {
                configuration.label
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        foregroundColor.opacity(
                            isEnabled ? 1 : 0.4
                        )
                    )
            }
        }
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .frame(height: 44)
        .padding(
            .horizontal,
            isFullWidth ? 0 : Theme.Spacing.s60
        )
        .background(
            backgroundColor(
                pressed: configuration.isPressed
            )
        )
        .clipShape(Capsule())
        .animation(
            .easeInOut(duration: 0.1),
            value: configuration.isPressed
        )
    }

    private func backgroundColor(
        pressed: Bool
    ) -> Color {
        switch variant {
        case .primary:
            return pressed
                ? Theme.Color.Primary.pressed
                : Theme.Color.Primary.resting
        case .secondary:
            return pressed
                ? Theme.Color.Border.light
                : Theme.Color.Surface.Background.highlight
        case .destructive:
            return pressed
                ? Theme.Color.Status.Error.resting
                    .opacity(0.85)
                : Theme.Color.Status.Error.resting
        case .ghost:
            return pressed
                ? Theme.Color.Border.faint
                : .clear
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:     return Theme.Color.Primary.text
        case .secondary:   return .white
        case .destructive: return .white
        case .ghost:       return .white
        }
    }
}

// MARK: - Convenience modifier

extension Button {
    func themed(
        _ variant: ButtonVariant = .primary,
        isLoading: Bool = false,
        fullWidth: Bool = true
    ) -> some View {
        self.buttonStyle(
            ButtonThemeStyle(
                variant: variant,
                isLoading: isLoading,
                isFullWidth: fullWidth
            )
        )
    }
}
