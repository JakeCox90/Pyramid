import SwiftUI

struct StoryTitleCard: View {
    let leagueName: String
    let gameweek: Int
    let aliveCount: Int
    let totalCount: Int

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s60) {
                Text("Gameweek \(gameweek)")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                Text(leagueName)
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                    .multilineTextAlignment(.center)

                HStack(spacing: Theme.Spacing.s20) {
                    Text("\(aliveCount)")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Color.Status.Success.resting)
                    Text("of \(totalCount) remaining")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel(
            "Gameweek \(gameweek), \(leagueName), \(aliveCount) of \(totalCount) players remaining"
        )
    }
}
