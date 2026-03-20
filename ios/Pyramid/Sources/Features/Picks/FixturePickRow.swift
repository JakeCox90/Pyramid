import SwiftUI

struct FixturePickRow: View {
    let fixture: Fixture
    let selectedTeamId: Int?
    let usedTeamIds: Set<Int>
    let isLocked: Bool
    let isSubmitting: Bool
    var submittingTeamId: Int?
    var celebratedTeamId: Int?
    var showCelebration: Bool = false
    let onPick: (Int, String) -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private var kickoffText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd MMM, HH:mm"
        return formatter.string(from: fixture.kickoffAt)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.s40) {
            fixtureHeader
            teamRow
            pickButtons
        }
        .padding(Theme.Spacing.s40)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
        )
    }
}

// MARK: - Header & Team Row

extension FixturePickRow {
    private var fixtureHeader: some View {
        HStack {
            Text(kickoffText)
                .font(Theme.Typography.caption1)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )

            Spacer()

            if fixture.status.isLive {
                HStack(spacing: Theme.Spacing.s10) {
                    PulsingDot()
                    Text(fixture.status.displayLabel)
                        .font(Theme.Typography.caption1.bold())
                        .foregroundStyle(
                            Theme.Color.Status.Error.resting
                        )
                }
            } else if fixture.status.isFinished {
                Text(fixture.status.displayLabel)
                    .font(Theme.Typography.caption1.bold())
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
            }
        }
    }

    private var teamRow: some View {
        HStack(spacing: Theme.Spacing.s20) {
            teamDisplay(
                teamId: fixture.homeTeamId,
                teamName: fixture.homeTeamName,
                logoURL: fixture.homeTeamLogo
            )
            .frame(maxWidth: .infinity)

            scoreOrVs
                .frame(width: 44)

            teamDisplay(
                teamId: fixture.awayTeamId,
                teamName: fixture.awayTeamName,
                logoURL: fixture.awayTeamLogo
            )
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var scoreOrVs: some View {
        if fixture.status.isLive || fixture.status.isFinished,
           let homeScore = fixture.homeScore,
           let awayScore = fixture.awayScore {
            Text("\(homeScore) - \(awayScore)")
                .font(Theme.Typography.title2)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                .monospacedDigit()
        } else {
            Text("vs")
                .font(Theme.Typography.caption1)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
        }
    }

    @ViewBuilder
    private func teamDisplay(
        teamId: Int,
        teamName: String,
        logoURL: String?
    ) -> some View {
        let isUsed = usedTeamIds.contains(teamId)
            && selectedTeamId != teamId

        VStack(spacing: Theme.Spacing.s20) {
            TeamBadge(
                teamName: teamName,
                logoURL: logoURL,
                size: 48
            )
            .opacity(isUsed ? 0.4 : 1.0)

            Text(teamName)
                .font(Theme.Typography.caption1.bold())
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// MARK: - Pick Buttons

extension FixturePickRow {
    private var pickButtons: some View {
        HStack(spacing: Theme.Spacing.s30) {
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
    }

    @ViewBuilder
    private func pickButton(
        teamId: Int,
        teamName: String,
        label: String
    ) -> some View {
        let isPicked = selectedTeamId == teamId
        let isUsed = usedTeamIds.contains(teamId) && !isPicked
        let isThisSubmitting = submittingTeamId == teamId
        let isOtherSubmitting = submittingTeamId != nil
            && !isThisSubmitting
        let isDisabled = isLocked || isSubmitting || isUsed

        Button {
            guard !isDisabled else { return }
            onPick(teamId, teamName)
        } label: {
            pickButtonLabel(
                isPicked: isPicked,
                isUsed: isUsed,
                isThisSubmitting: isThisSubmitting,
                label: label
            )
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(pickButtonBackground(isPicked: isPicked))
            .clipShape(Capsule())
            .opacity(pickButtonOpacity(
                isThisSubmitting: isThisSubmitting,
                isOtherSubmitting: isOtherSubmitting,
                isDisabled: isDisabled,
                isPicked: isPicked
            ))
            .scaleEffect(pickButtonScale(
                isPicked: isPicked, teamId: teamId
            ))
            .animation(
                reduceMotion ? nil : .spring(
                    response: 0.3, dampingFraction: 0.5
                ),
                value: celebratedTeamId
            )
            .overlay {
                if showCelebration && celebratedTeamId == teamId {
                    ConfettiView()
                }
            }
        }
        .disabled(isDisabled && !isPicked)
        .accessibilityLabel(pickAccessibilityLabel(
            teamName: teamName,
            isUsed: isUsed,
            isPicked: isPicked
        ))
        .accessibilityHint(
            isDisabled ? "" : "Double-tap to select this team"
        )
    }

    @ViewBuilder
    private func pickButtonLabel(
        isPicked: Bool,
        isUsed: Bool,
        isThisSubmitting: Bool,
        label: String
    ) -> some View {
        if isThisSubmitting {
            ProgressView()
                .tint(Theme.Color.Content.Text.default)
        } else if isUsed {
            Text("USED")
                .font(Theme.Typography.caption1.bold())
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
                .tracking(0.8)
        } else {
            Text(isPicked ? "PICKED" : label.uppercased())
                .font(Theme.Typography.caption1.bold())
                .foregroundStyle(
                    isPicked
                        ? Theme.Color.Primary.text
                        : Theme.Color.Content.Text.default
                )
                .tracking(0.8)
        }
    }

    private func pickButtonBackground(
        isPicked: Bool
    ) -> Color {
        isPicked
            ? Theme.Color.Primary.resting
            : Theme.Color.Surface.Background.highlight
    }

    private func pickButtonOpacity(
        isThisSubmitting: Bool,
        isOtherSubmitting: Bool,
        isDisabled: Bool,
        isPicked: Bool
    ) -> Double {
        if isThisSubmitting { return 0.7 }
        if isOtherSubmitting || (isDisabled && !isPicked) {
            return 0.4
        }
        return 1.0
    }

    private func pickButtonScale(
        isPicked: Bool, teamId: Int
    ) -> CGFloat {
        (!reduceMotion && isPicked && celebratedTeamId == teamId)
            ? 1.05 : 1.0
    }

    private func pickAccessibilityLabel(
        teamName: String, isUsed: Bool, isPicked: Bool
    ) -> String {
        if isUsed { return "\(teamName), already used" }
        if isPicked { return "\(teamName), picked" }
        return "Pick \(teamName)"
    }
}
