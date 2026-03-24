import SwiftUI

struct StoryWildcardCard: View {
    let player: WildcardPlayer

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s60) {
                Text("Wildcard Pick")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                VStack(spacing: Theme.Spacing.s20) {
                    Text(player.displayName)
                        .font(Theme.Typography.h3)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                        .multilineTextAlignment(.center)

                    Text(player.teamName)
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }

                Text(player.survived ? "Survived" : "Eliminated")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        player.survived
                            ? Theme.Color.Status.Success.resting
                            : Theme.Color.Status.Error.resting
                    )
                    .padding(.horizontal, Theme.Spacing.s50)
                    .padding(.vertical, Theme.Spacing.s20)
                    .background(
                        (player.survived
                            ? Theme.Color.Status.Success.resting
                            : Theme.Color.Status.Error.resting)
                            .opacity(0.15)
                    )
                    .clipShape(Capsule())
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel(
            "Wildcard pick: \(player.displayName) chose \(player.teamName) and \(player.survived ? "survived" : "was eliminated")"
        )
    }
}
