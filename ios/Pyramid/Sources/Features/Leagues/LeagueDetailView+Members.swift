import SwiftUI

// MARK: - Members list subviews

extension LeagueDetailView {

    var emptyMembersView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.League.members)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Border.default)
            Text("No other members yet")
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Text("Share the join code to invite players.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.top, Theme.Spacing.s70)
    }

    var membersList: some View {
        VStack(spacing: Theme.Spacing.s20) {
            if !viewModel.isDeadlinePassed() {
                HStack {
                    Image(systemName: Theme.Icon.Pick.locked)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    Text("Picks are hidden until kick-off")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.s40)
            }

            ForEach(viewModel.sortedMembers) { member in
                MemberRow(
                    member: member,
                    pick: viewModel.pick(for: member),
                    fixture: viewModel.pick(for: member).flatMap { viewModel.fixture(for: $0) },
                    deadlinePassed: viewModel.isDeadlinePassed()
                )
                .padding(.horizontal, Theme.Spacing.s40)
            }
        }
    }
}
