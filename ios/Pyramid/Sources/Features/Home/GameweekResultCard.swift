import SwiftUI

/// Compact result card shown per-league on the homepage after settlement.
/// Tapping opens the Gameweek Summary overlay at this league's position.
struct GameweekResultCard: View {
    let item: GameweekSummaryItem
    let onTap: () -> Void

    private var isSurvived: Bool {
        item.result == .survived
    }

    private var resultColor: Color {
        isSurvived
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.s30) {
                // Result icon
                Image(
                    systemName: isSurvived
                        ? "checkmark.seal.fill"
                        : "xmark.seal.fill"
                )
                .font(.system(size: 32))
                .foregroundStyle(resultColor)

                // Text stack
                VStack(
                    alignment: .leading,
                    spacing: Theme.Spacing.s10
                ) {
                    Text(isSurvived ? "Survived" : "Eliminated")
                        .font(Theme.Typography.h4)
                        .foregroundStyle(resultColor)

                    Text(pickSummary)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
            }
            .padding(Theme.Spacing.s40)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.r50
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var pickSummary: String {
        "You picked \(item.pickedTeamName) vs \(item.opponentName) \(item.homeScore)-\(item.awayScore)"
    }
}
