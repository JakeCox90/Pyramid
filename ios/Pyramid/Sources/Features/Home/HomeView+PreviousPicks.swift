import SwiftUI

// MARK: - Previous Picks Section

extension HomeView {
    @ViewBuilder
    func previousPicksSection(
        for league: League
    ) -> some View {
        let picks = viewModel.previousPicks(for: league)
        if !picks.isEmpty {
            VStack(
                alignment: .leading,
                spacing: Theme.Spacing.s50
            ) {
                Text("Previous picks")
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                            .opacity(0.2)
                    )

                ForEach(picks) { result in
                    ResultCard(
                        homeTeamName: result
                            .homeTeamName,
                        homeTeamShort: result
                            .homeTeamShort,
                        homeTeamLogo: result
                            .homeTeamLogo,
                        awayTeamName: result
                            .awayTeamName,
                        awayTeamShort: result
                            .awayTeamShort,
                        awayTeamLogo: result
                            .awayTeamLogo,
                        homeScore: result.homeScore,
                        awayScore: result.awayScore,
                        pickedHome: result.pickedHome,
                        result: result.result
                    )
                }
            }
            .padding(.top, Theme.Spacing.s60)
        }
    }
}
