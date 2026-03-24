import SwiftUI

// MARK: - League Row

struct LeagueRowView: View {
    let league: League

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(league.name)
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )

                    HStack(spacing: Theme.Spacing.s20) {
                        Text(league.status.displayName)
                            .font(Theme.Typography.overline)
                            .foregroundStyle(
                                Theme.Color.Content.Text.disabled
                            )

                        if let count = league.memberCount {
                            HStack(spacing: Theme.Spacing.s10) {
                                Image(systemName: Theme.Icon.League.members)
                                    .font(Theme.Typography.overline)
                                Text("\(count)")
                                    .font(Theme.Typography.overline)
                            }
                            .foregroundStyle(
                                Theme.Color.Content.Text.disabled
                            )
                        }
                    }
                }

                Spacer()

                Image(systemName: Theme.Icon.Navigation.disclosure)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Border.default)
            }
        }
    }
}