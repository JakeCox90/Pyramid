import SwiftUI

// MARK: - Pick Buttons

// Figma layout_F0GDNE: row, gap 24px, width 329, height 44
// layout_9PMINZ: padding 12px 24px, height 44, fill width
// fill_5J06A6: text #000000
// style_MY14W0: Inter Bold 12, uppercase, center

extension MatchCarouselCard {
    @ViewBuilder var pickButtons: some View {
        if isLocked {
            lockedPill
        } else {
            HStack(spacing: 12) {
                pickButton(
                    teamId: fixture.homeTeamId,
                    teamName: fixture.homeTeamName,
                    label: "PICK HOME"
                )
                statsIconButton
                pickButton(
                    teamId: fixture.awayTeamId,
                    teamName: fixture.awayTeamName,
                    label: "PICK AWAY"
                )
            }
        }
    }

    private var lockedPill: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16))
            Text("LOCKED")
                .font(Theme.Typography.label01)
        }
        .foregroundStyle(Theme.Color.Content.Text.disabled)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Theme.Color.Surface.Background.highlight)
        .overlay(
            Capsule()
                .stroke(
                    Theme.Color.Border.subtle,
                    lineWidth: 1
                )
        )
        .clipShape(Capsule())
    }

    /// Figma: IconButton (46:4119) — 44×44 circle,
    /// Bar Chart Icon 1 (46:4117) 24×24, black
    private var statsIconButton: some View {
        Button {
            onStats?()
        } label: {
            Image("bar-chart")
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(Theme.Color.Primary.text)
                .frame(width: 44, height: 44)
                .background(Theme.Color.Primary.resting)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
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
                teamId: teamId,
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
        teamId: Int,
        isPicked: Bool,
        isUsed: Bool,
        isLoading: Bool
    ) -> some View {
        if isLoading {
            ProgressView()
                .tint(Theme.Color.Primary.text)
        } else if isUsed {
            Text(usedLabel(for: teamId))
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Theme.Color.Content.Text.tertiary
                )
        } else {
            Text(isPicked ? "PICKED" : label)
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    isPicked
                        ? Theme.Color.Content.Text.default
                        : Theme.Color.Primary.text
                )
                .tracking(0.8)
        }
    }

    @ViewBuilder
    private func buttonBackground(
        isPicked: Bool,
        isUsed: Bool
    ) -> some View {
        if isPicked || isUsed {
            Theme.Color.Surface.Background.highlight
        } else {
            Theme.Color.Primary.resting
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

    private func usedLabel(for teamId: Int) -> String {
        if let round = usedTeamRounds[teamId] {
            return "USED GW\(round)"
        }
        return "USED"
    }
}
