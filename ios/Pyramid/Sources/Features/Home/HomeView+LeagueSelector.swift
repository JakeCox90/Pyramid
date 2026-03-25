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
            .foregroundStyle(.white)
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
            HStack(spacing: Theme.Spacing.s10) {
                if eliminated {
                    Image(
                        systemName: "xmark.circle.fill"
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(
                        isSelected
                            ? Color(hex: "FF453A")
                            : .white.opacity(0.5)
                    )
                }
                Text(league.name)
                    .font(Theme.Typography.label01)
                    .foregroundStyle(
                        isSelected
                            ? .white
                            : .white.opacity(0.5)
                    )
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s20)
            .background(
                isSelected
                    ? Color.white.opacity(0.15)
                    : Color.clear
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        Color.white.opacity(
                            isSelected ? 0 : 0.15
                        ),
                        lineWidth: 1
                    )
            )
            .animation(
                .easeInOut(duration: 0.2),
                value: isSelected
            )
        }
        .buttonStyle(.plain)
    }
}
