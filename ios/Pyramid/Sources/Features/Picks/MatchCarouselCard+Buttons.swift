import SwiftUI

// MARK: - Pick Buttons

// Figma layout_F0GDNE: row, gap 24px, width 329, height 44
// layout_9PMINZ: padding 12px 24px, height 44, fill width
// fill_LRKB3T: linear-gradient(44deg, black → white) over #FFC758
// fill_5J06A6: text #000000
// style_MY14W0: Inter Bold 12, uppercase, center

extension MatchCarouselCard {
    var pickButtons: some View {
        HStack(spacing: 12) {
            pickButton(
                teamId: fixture.homeTeamId,
                teamName: fixture.homeTeamName,
                label: "PICK HOME"
            )
            pickButton(
                teamId: fixture.awayTeamId,
                teamName: fixture.awayTeamName,
                label: "PICK AWAY"
            )
        }
    }

    @ViewBuilder
    private func pickButton(
        teamId: Int,
        teamName: String,
        label: String
    ) -> some View {
        let isPicked = selectedTeamId == teamId
        let isUsed = usedTeamIds.contains(teamId)
            && !isPicked
        let isThisSub = submittingTeamId == teamId
        let disabled = isLocked || isSubmitting || isUsed

        Button {
            guard !disabled else { return }
            onPick(teamId, teamName)
        } label: {
            buttonContent(
                label: label,
                isPicked: isPicked,
                isUsed: isUsed,
                isLoading: isThisSub
            )
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                buttonBackground(
                    isPicked: isPicked,
                    isUsed: isUsed
                )
            )
            .clipShape(Capsule())
            .opacity(
                buttonAlpha(
                    isPicked: isPicked,
                    isUsed: isUsed,
                    isLoading: isThisSub,
                    disabled: disabled
                )
            )
        }
        .disabled(disabled && !isPicked)
    }
}

// MARK: - Button Content

extension MatchCarouselCard {
    @ViewBuilder
    private func buttonContent(
        label: String,
        isPicked: Bool,
        isUsed: Bool,
        isLoading: Bool
    ) -> some View {
        if isLoading {
            ProgressView()
                .tint(Color.black)
        } else if isUsed {
            Text("USED")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color.white)
                .opacity(0.3)
        } else {
            Text(isPicked ? "PICKED" : label)
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    isPicked
                        ? Color.white
                        : Color(hex: "000000")
                )
                .tracking(0.8)
        }
    }

    // fill_LRKB3T: linear-gradient(44deg, black 0%,
    // white 100%) over #FFC758
    @ViewBuilder
    private func buttonBackground(
        isPicked: Bool,
        isUsed: Bool
    ) -> some View {
        if isPicked || isUsed {
            Color.white.opacity(0.1)
        } else {
            ZStack {
                Color(hex: "FFC758")
                LinearGradient(
                    colors: [.black, .white],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                .blendMode(.softLight)
            }
        }
    }

    private func buttonAlpha(
        isPicked: Bool,
        isUsed: Bool,
        isLoading: Bool,
        disabled: Bool
    ) -> Double {
        if isLoading { return 0.7 }
        if isUsed { return 1.0 }
        if disabled && !isPicked { return 0.4 }
        return 1.0
    }
}
