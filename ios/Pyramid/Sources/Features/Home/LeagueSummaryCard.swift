import SwiftUI

/// Rich league card for the homepage showing pick state, player count, and alive count.
struct LeagueSummaryCard: View {
    let league: League
    let memberStatus: LeagueMember.MemberStatus?
    let pick: Pick?
    let gameweek: Gameweek?

    var body: some View {
        NavigationLink(destination: LeagueDetailView(league: league)) {
            DSCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
                    headerRow
                    detailRow
                }
            }
            .opacity(isMuted ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(league.name)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .lineLimit(1)

            Spacer()

            Image(systemName: Theme.Icon.Navigation.disclosure)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
    }

    // MARK: - Detail Row

    private var detailRow: some View {
        HStack(spacing: Theme.Spacing.s30) {
            if let gameweek {
                detailLabel(
                    text: "GW\(gameweek.roundNumber)",
                    color: Theme.Color.Content.Text.disabled
                )
            }

            if let count = league.memberCount {
                HStack(spacing: Theme.Spacing.s10) {
                    Image(systemName: Theme.Icon.League.members)
                        .font(Theme.Typography.caption2)
                    Text("\(count)")
                        .font(Theme.Typography.caption1)
                }
                .foregroundStyle(Theme.Color.Content.Text.disabled)
            }

            Spacer()

            pickStateBadge
        }
    }

    // MARK: - Pick State Badge

    @ViewBuilder
    private var pickStateBadge: some View {
        if league.status == .completed {
            detailLabel(text: "Finished", color: Theme.Color.Content.Text.disabled)
        } else if memberStatus == .eliminated {
            detailLabel(
                text: "Eliminated",
                color: Theme.Color.Status.Error.resting
            )
        } else if let pick {
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: Theme.Icon.Status.success)
                    .font(Theme.Typography.caption2)
                Text(pick.teamName)
                    .font(Theme.Typography.caption1)
            }
            .foregroundStyle(
                pick.isLocked
                    ? Theme.Color.Status.Success.resting
                    : Theme.Color.Content.Text.subtle
            )
        } else if memberStatus == .active {
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: Theme.Icon.Status.errorFill)
                    .font(Theme.Typography.caption2)
                Text("No pick")
                    .font(Theme.Typography.caption1)
            }
            .foregroundStyle(Theme.Color.Status.Warning.resting)
        }
    }

    // MARK: - Helpers

    private var isMuted: Bool {
        league.status == .completed || memberStatus == .eliminated
    }

    private func detailLabel(text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.Typography.caption1)
            .foregroundStyle(color)
    }
}
