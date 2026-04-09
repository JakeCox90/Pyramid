import SwiftUI

// MARK: - Elimination Section

extension HomeView {
    @ViewBuilder
    func eliminationSection(
        for league: League
    ) -> some View {
        if let result = viewModel.eliminationResult(
            for: league
        ) {
            OutcomeCard.from(result: result, variant: .eliminated)
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
