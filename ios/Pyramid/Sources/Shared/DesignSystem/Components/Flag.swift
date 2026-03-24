import SwiftUI

// MARK: - Flag

enum FlagVariant {
    case success, error, neutral, warning

    var foreground: Color {
        switch self {
        case .success:
            return Theme.Color.Status.Success.resting
        case .error:
            return Theme.Color.Status.Error.resting
        case .neutral:
            return Theme.Color.Content.Text.subtle
        case .warning:
            return Theme.Color.Status.Warning.resting
        }
    }

    var background: Color {
        switch self {
        case .success:
            return Theme.Color.Status.Success.subtle
        case .error:
            return Theme.Color.Status.Error.subtle
        case .neutral:
            return Theme.Color.Surface.Background.page
        case .warning:
            return Theme.Color.Status.Warning.subtle
        }
    }
}

struct Flag: View {
    let label: String
    let variant: FlagVariant

    var body: some View {
        Text(label)
            .font(Theme.Typography.overline)
            .fontWeight(.semibold)
            .foregroundStyle(variant.foreground)
            .padding(.vertical, Theme.Spacing.s10)
            .padding(.horizontal, Theme.Spacing.s20)
            .background(variant.background)
            .clipShape(Capsule())
    }
}

// MARK: - PickStatus (domain mapping)

enum PickStatus {
    case survived, eliminated, pending, void

    var label: String {
        switch self {
        case .survived: return "Survived"
        case .eliminated: return "Eliminated"
        case .pending: return "Pending"
        case .void: return "Void"
        }
    }

    var flagVariant: FlagVariant {
        switch self {
        case .survived: return .success
        case .eliminated: return .error
        case .pending: return .neutral
        case .void: return .warning
        }
    }
}
