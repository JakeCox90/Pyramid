import SwiftUI

struct StoryMassElimCard: View {
    let playerCount: Int

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s60) {
                Text("Mass Elimination")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                Image(systemName: "bolt.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                Text("Everyone Out")
                    .font(Theme.Typography.title1)
                    .foregroundStyle(Theme.Color.Content.Text.default)

                Text("\(playerCount) player\(playerCount == 1 ? "" : "s") eliminated in one go")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel(
            "Mass elimination: \(playerCount) player\(playerCount == 1 ? "" : "s") eliminated this gameweek"
        )
    }
}
