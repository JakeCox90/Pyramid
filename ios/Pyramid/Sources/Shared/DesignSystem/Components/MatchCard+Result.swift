import SwiftUI

// MARK: - Result Layout (Live / Finished)

extension MatchCard {
    var resultContent: some View {
        VStack(spacing: 0) {
            badge
            Spacer().frame(height: 12)
            yourPickLabel
            Spacer().frame(height: 4)
            pickedTeamTitle
            Spacer().frame(height: 4)
            scoreDisplay
            Spacer().frame(height: 4)
            opponentTitle
            Spacer().frame(height: 12)
            statusFlag
            Spacer()
            if phase == .live {
                resultBottomSection
            }
        }
    }

    var scoreDisplay: some View {
        Text(scoreText)
            .font(Theme.Typography.display)
            .foregroundStyle(
                Theme.Color.Content.Text.default
            )
            .monospacedDigit()
    }

    @ViewBuilder var statusFlag: some View {
        switch phase {
        case .live:
            Flag(label: "LIVE", variant: .live)
        case .finished:
            if let survived {
                Flag(
                    label: survived
                        ? "SURVIVED" : "ELIMINATED",
                    variant: survived
                        ? .survived : .eliminated
                )
            } else {
                Flag(label: "FT", variant: .fullTime)
            }
        case .preMatch:
            EmptyView()
        }
    }

    var resultBottomSection: some View {
        VStack(spacing: 0) {
            lockedPill
                .padding(.top, 12)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
        }
    }
}
