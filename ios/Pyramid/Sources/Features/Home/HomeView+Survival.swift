import SwiftUI

// MARK: - Survival Celebration Trigger

extension HomeView {
    /// Checks if the user survived in any league this gameweek
    /// and triggers the celebration overlay for the first one found.
    /// Uses AppStorage so the overlay only shows once per league per GW.
    func checkForSurvival(data: HomeData?) {
        guard let data else { return }
        // Don't show if elimination overlay is active
        guard !showEliminationOverlay else { return }
        guard !showSurvivalOverlay else { return }

        for league in data.leagues {
            // Only trigger for active members (not eliminated)
            guard data.memberStatuses[league.id]
                    == .active else { continue }

            // Find a survived result from last GW
            guard let result = data.lastGwResults.first(
                where: {
                    $0.leagueId == league.id
                        && $0.result == .survived
                }
            ) else { continue }

            let key = "survival_seen_\(league.id)_\(result.gameweekName)"
            guard !UserDefaults.standard.bool(
                forKey: key
            ) else { continue }

            UserDefaults.standard.set(
                true, forKey: key
            )
            survivalOverlayResult = result
            showSurvivalOverlay = true
            return
        }
    }

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
