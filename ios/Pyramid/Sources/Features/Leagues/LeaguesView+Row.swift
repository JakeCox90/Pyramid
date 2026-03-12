import SwiftUI

// MARK: - League Row

struct LeagueRowView: View {
    let league: League

    var body: some View {
        DSCard {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(league.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )

                    HStack(spacing: Theme.Spacing.s20) {
                        Text(league.status.displayName)
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(
                                Theme.Color.Content.Text.disabled
                            )

                        if let count = league.memberCount {
                            HStack(spacing: Theme.Spacing.s10) {
                                Image(systemName: Theme.Icon.League.members)
                                    .font(Theme.Typography.caption2)
                                Text("\(count)")
                                    .font(Theme.Typography.caption1)
                            }
                            .foregroundStyle(
                                Theme.Color.Content.Text.disabled
                            )
                        }
                    }
                }

                Spacer()

                Image(systemName: Theme.Icon.Navigation.disclosure)
                    .font(.caption)
                    .foregroundStyle(Theme.Color.Border.default)
            }
        }
    }
}

extension League.LeagueStatus {
    var displayName: String {
        switch self {
        case .pending:   return "Waiting for players"
        case .active:    return "In progress"
        case .completed: return "Finished"
        case .cancelled: return "Cancelled"
        }
    }
}
