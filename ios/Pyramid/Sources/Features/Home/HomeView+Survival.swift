import SwiftUI

// MARK: - Survival Section

extension HomeView {
    /// Shows a SurvivalCard for a league the user survived in,
    /// used in the homepage per-league content when the last GW
    /// result was a survival.
    @ViewBuilder
    func survivalSection(
        for league: League
    ) -> some View {
        if let result = viewModel.survivalResult(
            for: league
        ) {
            SurvivalCard.from(result: result)
        }
    }
}
