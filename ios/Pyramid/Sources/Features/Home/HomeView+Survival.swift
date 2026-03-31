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
        } else {
            // Survived but match data hasn't loaded yet
            survivalFallback(for: league)
        }
    }

    /// Fallback card when survival result data hasn't loaded.
    private func survivalFallback(
        for league: League
    ) -> some View {
        VStack(spacing: Theme.Spacing.s30) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    Theme.Color.Status.Success.resting
                )

            Text("SURVIVED")
                .font(Theme.Typography.overline)
                .tracking(2)
                .foregroundStyle(
                    Theme.Color.Status.Success.resting
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
