import SwiftUI

// MARK: - League Selector Strip

extension HomeView {
    @ViewBuilder var leagueSelector: some View {
        let leagues = viewModel.homeData?.leagues ?? []
        if leagues.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s20) {
                    ForEach(leagues) { league in
                        leaguePill(league)
                    }
                }
                .padding(.horizontal, Theme.Spacing.s40)
            }
            // Escape parent's horizontal padding so pills scroll edge-to-edge
            .padding(.horizontal, -Theme.Spacing.s40)
        } else if let league = leagues.first {
            // Single league — show as static label for context
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                Text(league.name)
                    .font(Theme.Typography.label01)
            }
            .foregroundStyle(Theme.Color.Content.Text.default)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func leaguePill(
        _ league: League
    ) -> some View {
        let isSelected = league.id
            == viewModel.selectedLeague?.id
        let eliminated = viewModel.isEliminated(
            in: league
        )
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectLeague(league)
            }
        } label: {
            leaguePillLabel(
                league,
                isSelected: isSelected,
                eliminated: eliminated
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func leaguePillLabel(
        _ league: League,
        isSelected: Bool,
        eliminated: Bool
    ) -> some View {
        HStack(spacing: Theme.Spacing.s10) {
            if eliminated {
                Image(systemName: "xmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        isSelected
                            ? Theme.Color.Match.Pill.negative
                            : Theme.Color.Content.Text.subtle
                    )
            }
            Text(league.name)
                .font(Theme.Typography.label01)
                .foregroundStyle(
                    isSelected
                        ? Theme.Color.Content.Text.default
                        : Theme.Color.Content.Text.subtle
                )
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s20)
        .background(
            isSelected
                ? Theme.Color.Border.default
                : Color.clear
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected
                        ? Color.clear
                        : Theme.Color.Border.default,
                    lineWidth: 1
                )
        )
        .animation(
            .easeInOut(duration: 0.2),
            value: isSelected
        )
    }
}
