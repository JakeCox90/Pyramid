import SwiftUI

// MARK: - Elimination Section & Overlay Trigger

extension HomeView {
    /// Checks if the user was just eliminated in any league
    /// and triggers the full-screen overlay for the first one found.
    /// Uses AppStorage so the overlay only shows once per league.
    func checkForElimination(data: HomeData?) {
        guard let data else { return }
        // Don't re-show if already showing
        guard !showEliminationOverlay else { return }

        for league in data.leagues {
            guard data.memberStatuses[league.id]
                    == .eliminated else { continue }
            let key = "elimination_seen_\(league.id)"
            guard !UserDefaults.standard.bool(
                forKey: key
            ) else { continue }
            // Find the elimination result
            if let result = data.lastGwResults.first(
                where: {
                    $0.leagueId == league.id
                        && $0.result == .eliminated
                }
            ) {
                UserDefaults.standard.set(
                    true, forKey: key
                )
                eliminationOverlayResult = result
                showEliminationOverlay = true
                return
            }
        }
    }

    @ViewBuilder
    func eliminationSection(
        for league: League
    ) -> some View {
        if let result = viewModel.eliminationResult(
            for: league
        ) {
            EliminationCard.from(result: result)
        } else {
            // Eliminated but no match data available yet
            eliminationFallback(for: league)
        }
    }

    /// Fallback card when elimination result data hasn't loaded.
    private func eliminationFallback(
        for league: League
    ) -> some View {
        VStack(spacing: Theme.Spacing.s30) {
            Image(systemName: "xmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )

            Text("ELIMINATED")
                .font(Theme.Typography.overline)
                .tracking(2)
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )

            Text(league.name)
                .font(Theme.Typography.h3)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s80)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    Theme.Color.Surface
                        .Background.container
                )
        )
    }
}
