import SwiftUI

struct FixturePickRow: View {
    let fixture: Fixture
    let selectedTeamId: Int?
    let usedTeamIds: Set<Int>
    let isLocked: Bool
    let isSubmitting: Bool
    var celebratedTeamId: Int?
    var showCelebration: Bool = false
    let onPick: (Int, String) -> Void

    private var kickoffText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd MMM, HH:mm"
        return formatter.string(from: fixture.kickoffAt)
    }

    var body: some View {
        DSCard {
            VStack(spacing: Theme.Spacing.s30) {
                Text(kickoffText)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
                    .frame(maxWidth: .infinity)

                HStack(spacing: Theme.Spacing.s30) {
                    teamButton(
                        teamId: fixture.homeTeamId,
                        teamName: fixture.homeTeamName,
                        shortName: fixture.homeTeamShort,
                        logoURL: fixture.homeTeamLogo,
                        score: fixture.homeScore
                    )

                    VStack(spacing: Theme.Spacing.s10) {
                        if fixture.status.isLive || fixture.status.isFinished {
                            Text(fixture.status.displayLabel)
                                .font(Theme.Typography.caption1.bold())
                                .foregroundStyle(
                                    fixture.status.isLive
                                        ? Theme.Color.Status.Error.resting
                                        : Theme.Color.Content.Text.disabled
                                )
                        } else {
                            Text("vs")
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Color.Content.Text.disabled)
                        }
                    }

                    teamButton(
                        teamId: fixture.awayTeamId,
                        teamName: fixture.awayTeamName,
                        shortName: fixture.awayTeamShort,
                        logoURL: fixture.awayTeamLogo,
                        score: fixture.awayScore
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func teamButton(
        teamId: Int,
        teamName: String,
        shortName: String,
        logoURL: String?,
        score: Int?
    ) -> some View {
        let isPicked = selectedTeamId == teamId
        let isUsed = usedTeamIds.contains(teamId) && !isPicked
        let isDisabled = isLocked || isSubmitting || isUsed

        Button {
            guard !isDisabled else { return }
            onPick(teamId, teamName)
        } label: {
            VStack(spacing: Theme.Spacing.s10) {
                if let score {
                    Text("\(score)")
                        .font(Theme.Typography.title2.bold())
                        .foregroundStyle(Theme.Color.Content.Text.default)
                }
                TeamBadge(logoURL: logoURL, shortName: shortName, size: 32)
                Text(teamName)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(isPicked ? Color.white.opacity(0.8) : Theme.Color.Content.Text.disabled)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if isUsed {
                    Text("Used")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Color.Status.Error.resting)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.s30)
            .background(isPicked ? Theme.Color.Content.Text.default : Theme.Color.Surface.Background.page)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isPicked ? Theme.Color.Content.Text.default : Theme.Color.Border.default, lineWidth: 1)
            )
            .opacity(isDisabled && !isPicked ? 0.5 : 1.0)
            .scaleEffect(isPicked && celebratedTeamId == teamId ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: celebratedTeamId)
            .overlay {
                if showCelebration && celebratedTeamId == teamId {
                    ConfettiView()
                }
            }
        }
        .disabled(isDisabled && !isPicked)
    }
}
