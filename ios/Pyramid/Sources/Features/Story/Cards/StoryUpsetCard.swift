import SwiftUI

struct StoryUpsetCard: View {
    let fixture: Fixture
    let eliminationCount: Int

    private var homeScore: String {
        fixture.homeScore.map { "\($0)" } ?? "-"
    }

    private var awayScore: String {
        fixture.awayScore.map { "\($0)" } ?? "-"
    }

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s60) {
                Text("Biggest Upset")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                VStack(spacing: Theme.Spacing.s30) {
                    HStack(spacing: Theme.Spacing.s40) {
                        Text(fixture.homeTeamName)
                            .font(Theme.Typography.subhead)
                            .foregroundStyle(Theme.Color.Content.Text.default)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        Text("\(homeScore) - \(awayScore)")
                            .font(Theme.Typography.h3)
                            .foregroundStyle(Theme.color(light: "FFC758", dark: "FFC758"))

                        Text(fixture.awayTeamName)
                            .font(Theme.Typography.subhead)
                            .foregroundStyle(Theme.Color.Content.Text.default)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Text("\(eliminationCount) player\(eliminationCount == 1 ? "" : "s") eliminated")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            }
            .padding(Theme.Spacing.s70)
        }
        .accessibilityLabel(
            "Biggest upset: \(fixture.homeTeamName) \(homeScore) - \(awayScore) \(fixture.awayTeamName). "
            + "\(eliminationCount) player\(eliminationCount == 1 ? "" : "s") eliminated."
        )
    }
}
