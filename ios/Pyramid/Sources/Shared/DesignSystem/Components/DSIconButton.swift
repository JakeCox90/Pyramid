import SwiftUI

// MARK: - DS Icon Button

struct DSIconButton: View {
    let icon: String
    let variant: DSButtonVariant
    let action: () -> Void

    init(
        icon: String,
        variant: DSButtonVariant = .primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(backgroundColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return Color(hex: "FFC758")
        case .secondary:
            return Color.white.opacity(0.2)
        case .destructive:
            return Theme.Color.Status.Error.resting
        case .ghost:
            return .clear
        }
    }

    private var iconColor: Color {
        switch variant {
        case .primary:     return .black
        case .secondary:   return .white
        case .destructive: return .white
        case .ghost:       return .white
        }
    }
}
