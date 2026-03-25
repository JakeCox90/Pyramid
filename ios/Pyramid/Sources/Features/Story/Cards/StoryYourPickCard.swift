import SwiftUI

struct StoryYourPickCard: View {
    let pick: YourPickResult

    private var statusColor: Color {
        switch pick.status {
        case .survived, .voidSurvived, .winner:
            return Theme.Color.Status.Success.resting
        case .eliminated, .missedDeadline:
            return Theme.Color.Status.Error.resting
        }
    }

    private var statusLabel: String {
        switch pick.status {
        case .survived: return "You survived"
        case .eliminated: return "You're out"
        case .winner: return "You won!"
        case .missedDeadline: return "Missed deadline"
        case .voidSurvived: return "Void — survived"
        }
    }

    private var statusIcon: String {
        switch pick.status {
        case .survived: return "checkmark.circle.fill"
        case .eliminated: return "xmark.circle.fill"
        case .winner: return "trophy.fill"
        case .missedDeadline: return "clock.badge.exclamationmark.fill"
        case .voidSurvived: return "checkmark.circle.badge.questionmark"
        }
    }

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s60) {
                Text("Your Pick")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Primary.resting)

                Image(systemName: statusIcon)
                    .font(.system(size: 56))
                    .foregroundStyle(statusColor)

                VStack(spacing: Theme.Spacing.s20) {
                    if let teamName = pick.teamName {
                        Text(teamName)
                            .font(Theme.Typography.h3)
                            .foregroundStyle(Theme.Color.Content.Text.default)
                    } else {
                        Text("No pick")
                            .font(Theme.Typography.h3)
                            .foregroundStyle(Theme.Color.Content.Text.subtle)
                    }

                    Text(statusLabel)
                        .font(Theme.Typography.body)
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, Theme.Spacing.s50)
                        .padding(.vertical, Theme.Spacing.s20)
                        .background(statusColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel(
            "Your pick: \(pick.teamName ?? "no pick"). \(statusLabel)"
        )
    }
}
