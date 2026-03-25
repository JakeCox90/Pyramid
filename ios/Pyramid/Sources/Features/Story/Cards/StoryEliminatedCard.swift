import SwiftUI

struct StoryEliminatedCard: View {
    let players: [EliminatedPlayer]

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s50) {
                Text("Eliminated")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                Text("\(players.count) out this week")
                    .font(Theme.Typography.h3)
                    .foregroundStyle(Theme.Color.Status.Error.resting)

                ScrollView {
                    VStack(spacing: Theme.Spacing.s20) {
                        ForEach(players) { player in
                            HStack {
                                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                                    Text(player.displayName)
                                        .font(Theme.Typography.body)
                                        .foregroundStyle(Theme.Color.Content.Text.default)

                                    if player.isAutoEliminated {
                                        Text("Missed deadline")
                                            .font(Theme.Typography.caption)
                                            .foregroundStyle(Theme.Color.Status.Warning.resting)
                                    } else {
                                        Text(player.teamName)
                                            .font(Theme.Typography.caption)
                                            .foregroundStyle(Theme.Color.Content.Text.subtle)
                                    }
                                }
                                Spacer()
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Theme.Color.Status.Error.resting)
                                    .font(.system(size: 20))
                            }
                            .padding(.horizontal, Theme.Spacing.s40)
                            .padding(.vertical, Theme.Spacing.s30)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r20))
                        }
                    }
                }
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel(
            "\(players.count) player\(players.count == 1 ? "" : "s") eliminated this week: "
            + players.map { "\($0.displayName), \($0.isAutoEliminated ? "missed deadline" : $0.teamName)" }
                .joined(separator: "; ")
        )
    }
}
