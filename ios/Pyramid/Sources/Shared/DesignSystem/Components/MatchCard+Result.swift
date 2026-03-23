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
            switch phase {
            case .live:
                livePill
            case .finished:
                finishedPill
            case .preMatch:
                EmptyView()
            }
            Spacer()
            if phase == .live {
                resultBottomSection
            }
        }
    }

    var scoreDisplay: some View {
        Text(scoreText)
            .font(Theme.Typography.display)
            .foregroundStyle(.white)
            .monospacedDigit()
    }

    /// Green capsule pill: #51B56A bg, 200px radius
    var livePill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.1),
                            lineWidth: 2
                        )
                )
            Text("LIVE")
                .font(Theme.Typography.overline)
                .foregroundStyle(.white)
        }
        .padding(.vertical, 4)
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .background(Color(hex: "51B56A"))
        .clipShape(Capsule())
    }

    /// Pill shown when the match is finished.
    /// Shows survived/eliminated when the result is known,
    /// otherwise a neutral FT pill.
    @ViewBuilder var finishedPill: some View {
        if let survived {
            HStack(spacing: 6) {
                Image(
                    systemName: survived
                        ? "checkmark.circle.fill"
                        : "xmark.circle.fill"
                )
                .font(.system(size: 14))
                Text(survived ? "SURVIVED" : "ELIMINATED")
                    .font(Theme.Typography.overline)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                survived
                    ? Color(hex: "51B56A")
                    : Color(hex: "FF453A")
            )
            .clipShape(Capsule())
        } else {
            Text("FT")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white.opacity(0.6))
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
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
