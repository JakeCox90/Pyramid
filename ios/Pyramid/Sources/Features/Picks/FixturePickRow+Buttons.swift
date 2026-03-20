import SwiftUI

// MARK: - Pick Buttons

// Figma layout_PDPJ4P: x:12, y:151, width:329, height:44, gap:12px
// Figma layout_LYCBPN: padding 12px 24px, height 44, fill width
// Figma fill_RNW9LA: rgba(255,255,255,0.1), border-radius 200px

extension FixturePickRow {
    var pickButtons: some View {
        HStack(spacing: 12) {
            pickButton(
                teamId: fixture.homeTeamId,
                teamName: fixture.homeTeamName,
                label: "Home"
            )
            pickButton(
                teamId: fixture.awayTeamId,
                teamName: fixture.awayTeamName,
                label: "Away"
            )
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    func pickButton(
        teamId: Int,
        teamName: String,
        label: String
    ) -> some View {
        let state = buttonState(
            teamId: teamId
        )

        Button {
            guard !state.isDisabled else { return }
            onPick(teamId, teamName)
        } label: {
            buttonContent(state: state, label: label)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(state.fill)
                .clipShape(Capsule())
                .opacity(state.alpha)
                .scaleEffect(state.scale)
                .animation(
                    reduceMotion ? nil : .spring(
                        response: 0.3,
                        dampingFraction: 0.5
                    ),
                    value: celebratedTeamId
                )
                .overlay {
                    if state.showConfetti {
                        ConfettiView()
                    }
                }
        }
        .disabled(state.isDisabled && !state.isPicked)
        .accessibilityLabel(
            state.accessibilityLabel(teamName)
        )
        .accessibilityHint(
            state.isDisabled
                ? ""
                : "Double-tap to select this team"
        )
    }
}

// MARK: - Button State

extension FixturePickRow {
    struct ButtonState {
        let isPicked: Bool
        let isUsed: Bool
        let isThisSubmitting: Bool
        let isDisabled: Bool
        let fill: Color
        let alpha: Double
        let scale: CGFloat
        let showConfetti: Bool

        func accessibilityLabel(_ name: String) -> String {
            if isUsed { return "\(name), already used" }
            if isPicked { return "\(name), picked" }
            return "Pick \(name)"
        }
    }

    func buttonState(teamId: Int) -> ButtonState {
        let isPicked = selectedTeamId == teamId
        let isUsed = usedTeamIds.contains(teamId)
            && !isPicked
        let isThisSub = submittingTeamId == teamId
        let isOtherSub = submittingTeamId != nil
            && !isThisSub
        let disabled = isLocked || isSubmitting || isUsed

        // fill_RNW9LA: rgba(255,255,255,0.1)
        let fill = isPicked
            ? Theme.Color.Primary.resting
            : Color.white.opacity(0.1) // fill_RNW9LA

        var alpha = 1.0
        if isThisSub {
            alpha = 0.7
        } else if isUsed {
            alpha = 1.0
        } else if isOtherSub || (disabled && !isPicked) {
            alpha = 0.4
        }

        let scale: CGFloat =
            (!reduceMotion && isPicked
                && celebratedTeamId == teamId)
                ? 1.05 : 1.0

        let confetti = showCelebration
            && celebratedTeamId == teamId

        return ButtonState(
            isPicked: isPicked,
            isUsed: isUsed,
            isThisSubmitting: isThisSub,
            isDisabled: disabled,
            fill: fill,
            alpha: alpha,
            scale: scale,
            showConfetti: confetti
        )
    }
}

// MARK: - Button Content

extension FixturePickRow {
    @ViewBuilder
    func buttonContent(
        state: ButtonState, label: String
    ) -> some View {
        if state.isThisSubmitting {
            ProgressView()
                .tint(Color.white)
        } else if state.isUsed {
            Text("USED")
                .font(
                    Font.custom("Inter-Bold", size: 12)
                )
                .foregroundStyle(Color.white)
                .opacity(0.2)
                .tracking(0.8)
        } else {
            Text(
                state.isPicked
                    ? "PICKED"
                    : label.uppercased()
            )
            .font(Font.custom("Inter-Bold", size: 12))
            .foregroundStyle(
                state.isPicked
                    ? Theme.Color.Primary.text
                    : Color.white
            )
            .tracking(0.8)
        }
    }
}
