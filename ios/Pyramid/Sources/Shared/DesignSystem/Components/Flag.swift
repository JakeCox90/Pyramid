import SwiftUI

// MARK: - Flag

enum FlagVariant {
    case success, error, neutral, warning
    /// Green pill with pulsing dot — live match
    case live
    /// Neutral pill — full time, no result yet
    case fullTime
    /// Green pill with checkmark — survived
    case survived
    /// Red pill with xmark — eliminated
    case eliminated

    var foreground: Color {
        switch self {
        case .success, .survived:
            return Theme.Color.Status.Success.resting
        case .error, .eliminated:
            return Theme.Color.Status.Error.resting
        case .neutral, .fullTime:
            return Theme.Color.Content.Text.subtle
        case .warning:
            return Theme.Color.Status.Warning.resting
        case .live:
            return Theme.Color.Content.Text.default
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
        case .live, .survived:
            return Theme.Color.Match.Pill.positive
        case .eliminated:
            return Theme.Color.Match.Pill.negative
        case .fullTime:
            return Theme.Color.Surface.Background
                .highlight
        }
    }

    var icon: String? {
        switch self {
        case .survived: return "checkmark.circle.fill"
        case .eliminated: return "xmark.circle.fill"
        default: return nil
        }
    }

    var showDot: Bool {
        self == .live
    }

    /// Live/survived/eliminated use contrast text
    var usesContrastText: Bool {
        switch self {
        case .live, .survived, .eliminated:
            return true
        default:
            return false
        }
    }
}

struct Flag: View {
    let label: String
    let variant: FlagVariant

    var body: some View {
        HStack(spacing: 6) {
            if variant.showDot {
                PulsingDot()
            }
            if let icon = variant.icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
            }
            Text(label)
                .font(Theme.Typography.overline)
                .fontWeight(.semibold)
        }
        .foregroundStyle(
            variant.usesContrastText
                ? Theme.Color.Content.Text.default
                : variant.foreground
        )
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
