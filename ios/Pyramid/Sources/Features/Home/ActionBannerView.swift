import SwiftUI

/// Tappable action banner shown for each league where the user hasn't submitted a pick.
struct ActionBannerView: View {
    let league: League
    let gameweek: Gameweek?

    var body: some View {
        NavigationLink(destination: PicksView(leagueId: league.id)) {
            HStack(spacing: Theme.Spacing.s30) {
                Image(systemName: Theme.Icon.Status.errorFill)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.Status.Warning.resting)

                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text("Pick needed")
                        .font(Theme.Typography.subheadline.bold())
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    Text(league.name)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }

                Spacer()

                Image(systemName: Theme.Icon.Navigation.disclosure)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }
            .padding(Theme.Spacing.s40)
            .background(Theme.Color.Status.Warning.subtle)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.r30)
                    .stroke(Theme.Color.Status.Warning.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r30))
        }
        .buttonStyle(.plain)
    }
}
