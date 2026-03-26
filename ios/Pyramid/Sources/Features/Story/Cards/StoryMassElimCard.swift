import SwiftUI

struct StoryMassElimCard: View {
    let playerCount: Int

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s60) {
                Text("Mass Elimination")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Primary.resting)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Color.Primary.resting)

                Text("Everyone Out")
                    .font(Theme.Typography.h2)
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
