import SwiftUI

// MARK: - My Pick Card

extension LeagueDetailView {
    @ViewBuilder var myPickCard: some View {
        if viewModel.isCurrentUserEliminated {
            eliminationCardContent
                .padding(.horizontal, Theme.Spacing.s40)
        } else if viewModel.isDeadlinePassed(), let pick = viewModel.myPick {
            Card {
                if let fixture = viewModel.myFixture {
                    if fixture.status.isLive {
                        livePickContent(pick: pick, fixture: fixture)
                    } else if fixture.status.isFinished {
                        finishedPickContent(pick: pick, fixture: fixture)
                    } else {
                        preKickoffPickContent(pick: pick, fixture: fixture)
                    }
                } else {
                    basicPickContent(pick: pick)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(survivalBorderColor(pick: pick), lineWidth: 1.5)
            )
            .padding(.horizontal, Theme.Spacing.s40)
        }
    }

    @ViewBuilder private var eliminationCardContent: some View {
        if let pick = viewModel.eliminationPick,
           let fixture = viewModel.eliminationFixture,
           let gwName = viewModel.eliminationGameweekName {
            let pickedHome = pick.teamId == fixture.homeTeamId
            OutcomeCard(
                variant: .eliminated,
                leagueName: viewModel.league.name,
                gameweekName: gwName,
                pickedTeamName: pick.teamName,
                pickedTeamLogo: pickedHome
                    ? fixture.homeTeamLogo
                    : fixture.awayTeamLogo,
                opponentName: pickedHome
                    ? fixture.awayTeamName
                    : fixture.homeTeamName,
                homeTeamName: fixture.homeTeamName,
                homeTeamShort: fixture.homeTeamShort,
                homeTeamLogo: fixture.homeTeamLogo,
                awayTeamName: fixture.awayTeamName,
                awayTeamShort: fixture.awayTeamShort,
                awayTeamLogo: fixture.awayTeamLogo,
                homeScore: fixture.homeScore ?? 0,
                awayScore: fixture.awayScore ?? 0,
                pickedHome: pickedHome
            )
        }
    }

    // MARK: - Live State

    @ViewBuilder
    private func livePickContent(pick: MemberPick, fixture: Fixture) -> some View {
        let homeScore = fixture.homeScore ?? 0
        let awayScore = fixture.awayScore ?? 0
        let surviving = viewModel.isSurviving

        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            liveTopRow(fixture: fixture)

            scoreRow(
                homeShort: fixture.homeTeamShort,
                homeScore: homeScore,
                awayScore: awayScore,
                awayShort: fixture.awayTeamShort
            )

            survivalIndicator(surviving: surviving)
        }
    }

    @ViewBuilder
    private func liveTopRow(fixture: Fixture) -> some View {
        HStack(spacing: Theme.Spacing.s20) {
            Text("YOUR PICK")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .textCase(.uppercase)

            Spacer()

            PulsingDot()

            Text(fixture.status.displayLabel)
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Status.Error.resting)
                .monospacedDigit()
        }
    }

    // MARK: - Finished State

    @ViewBuilder
    private func finishedPickContent(pick: MemberPick, fixture: Fixture) -> some View {
        let homeScore = fixture.homeScore ?? 0
        let awayScore = fixture.awayScore ?? 0

        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            HStack {
                Text("YOUR PICK")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                    .textCase(.uppercase)

                Spacer()

                Text("FT")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
                    .padding(.horizontal, Theme.Spacing.s10)
                    .padding(.vertical, 2)
                    .background(Theme.Color.Surface.Background.container)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            scoreRow(
                homeShort: fixture.homeTeamShort,
                homeScore: homeScore,
                awayScore: awayScore,
                awayShort: fixture.awayTeamShort
            )

            finishedResultBadge(for: pick.result)
        }
    }

    // MARK: - Pre-Kickoff State (deadline passed, match not started)

    @ViewBuilder
    private func preKickoffPickContent(pick: MemberPick, fixture: Fixture) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
            Text("YOUR PICK")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .textCase(.uppercase)

            Text(pick.teamName)
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)

            Text("Kicks off at \(kickoffTimeString(fixture.kickoffAt))")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Fallback (fixture not yet loaded)

    @ViewBuilder
    private func basicPickContent(pick: MemberPick) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
            Text("YOUR PICK")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .textCase(.uppercase)

            Text(pick.teamName)
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Shared Sub-Views

    @ViewBuilder
    private func scoreRow(
        homeShort: String,
        homeScore: Int,
        awayScore: Int,
        awayShort: String
    ) -> some View {
        HStack {
            Text(homeShort)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.subtle)

            Spacer()

            Text("\(homeScore)  \u{2013}  \(awayScore)")
                .font(Theme.Typography.h3)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .monospacedDigit()

            Spacer()

            Text(awayShort)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
    }

    @ViewBuilder
    private func survivalIndicator(surviving: Bool?) -> some View {
        if let surviving {
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: surviving ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(
                        surviving
                            ? Theme.Color.Status.Success.resting
                            : Theme.Color.Status.Error.resting
                    )
                    .accessibilityHidden(true)
                Text(surviving ? "Surviving" : "In Danger")
                    .font(Theme.Typography.body)
                    .foregroundStyle(
                        surviving
                            ? Theme.Color.Status.Success.resting
                            : Theme.Color.Status.Error.resting
                    )
            }
            .accessibilityLabel(surviving ? "Surviving" : "In danger")
        } else {
            HStack(spacing: Theme.Spacing.s10) {
                Image(systemName: "circle.dotted")
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
                    .accessibilityHidden(true)
                Text("Pending")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
            .accessibilityLabel("Pending")
        }
    }

    @ViewBuilder
    private func finishedResultBadge(for result: PickResult) -> some View {
        switch result {
        case .survived:
            Label("Survived", systemImage: "checkmark.circle.fill")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Status.Success.resting)
        case .eliminated:
            Label("Eliminated", systemImage: "xmark.circle.fill")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Status.Error.resting)
        case .pending:
            Label("Pending Result", systemImage: "clock")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        case .void:
            Label("Void", systemImage: "minus.circle")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        }
    }

    // MARK: - Helpers

    private func survivalBorderColor(pick: MemberPick) -> Color {
        guard let fixture = viewModel.myFixture else { return Color.clear }
        guard fixture.status.isLive || fixture.status.isFinished else { return Color.clear }
        guard let surviving = viewModel.isSurviving else { return Color.clear }
        return surviving
            ? Theme.Color.Status.Success.resting
            : Theme.Color.Status.Error.resting
    }

    private func kickoffTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
