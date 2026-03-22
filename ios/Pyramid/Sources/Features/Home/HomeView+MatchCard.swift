import SwiftUI

// MARK: - Hero Match Card

extension HomeView {
    @ViewBuilder
    func matchCard(
        _ context: LivePickContext
    ) -> some View {
        let fixture = context.fixture
        let pickedHome = context.pick.teamId
            == fixture.homeTeamId
        let pickedTeam = pickedHome
            ? fixture.homeTeamName : fixture.awayTeamName
        let opponent = pickedHome
            ? fixture.awayTeamName : fixture.homeTeamName
        let badgeLogo = pickedHome
            ? fixture.homeTeamLogo : fixture.awayTeamLogo

        ZStack {
            matchCardBackground
            matchCardContent(
                pickedTeam: pickedTeam,
                opponent: opponent,
                badgeName: pickedTeam,
                badgeLogo: badgeLogo,
                kickoff: fixture.kickoffAt,
                fixture: fixture
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 446)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r50)
        )
    }

    @ViewBuilder
    func matchCardEmpty() -> some View {
        let locked = viewModel.isGameweekLocked
        ZStack {
            matchCardBackground
            VStack(spacing: Theme.Spacing.s40) {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            Color.white.opacity(0.4)
                        )
                    Text("LOCKED")
                        .font(Theme.Typography.overline)
                        .foregroundStyle(
                            Color.white.opacity(0.4)
                        )
                    Text("Gameweek in progress")
                        .font(Theme.Typography.h3)
                        .foregroundStyle(.white)
                } else {
                    Text("NO PICK YET")
                        .font(Theme.Typography.overline)
                        .foregroundStyle(
                            Color.white.opacity(0.4)
                        )
                    Text("Make your pick")
                        .font(Theme.Typography.h2)
                        .foregroundStyle(.white)
                    changePickButton
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 446)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r50)
        )
    }
}

// MARK: - Card Internals

extension HomeView {
    private var matchCardBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: "5E4E81"),
                Color(hex: "2D253D")
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    private func matchCardContent(
        pickedTeam: String,
        opponent: String,
        badgeName: String,
        badgeLogo: String?,
        kickoff: Date?,
        fixture: Fixture
    ) -> some View {
        let locked = viewModel.isGameweekLocked
        let isLive = fixture.status.isLive

        return VStack(spacing: Theme.Spacing.s30) {
            Spacer().frame(height: Theme.Spacing.s20)

            TeamBadge(
                teamName: badgeName,
                logoURL: badgeLogo,
                size: 120
            )
            .shadow(
                color: .black.opacity(0.4),
                radius: 16, x: 0, y: 8
            )

            if isLive {
                liveIndicator
            }

            Text("YOUR PICK")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )

            Text(pickedTeam)
                .font(Theme.Typography.h2)
                .foregroundStyle(.white)

            liveVsCircle(fixture: fixture)

            Text(opponent)
                .font(Theme.Typography.h3)
                .foregroundStyle(.white)

            if let kickoff, !isLive {
                Text(kickoffLabel(kickoff))
                    .font(Theme.Typography.overline)
                    .foregroundStyle(
                        Color.white.opacity(0.4)
                    )
            }

            if locked {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text("LOCKED")
                        .font(Theme.Typography.overline)
                }
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )
            } else {
                changePickButton
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var liveIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: "30D158"))
                .frame(width: 8, height: 8)
            Text("LIVE")
                .font(Theme.Typography.overline)
                .foregroundStyle(Color(hex: "30D158"))
        }
    }

    private func liveVsCircle(
        fixture: Fixture
    ) -> some View {
        let showScore = fixture.status.isLive
            || fixture.status.isFinished
        return Text(
            showScore
                ? "\(fixture.homeScore ?? 0) - \(fixture.awayScore ?? 0)"
                : "vs"
        )
        .font(Theme.Typography.label01)
        .foregroundStyle(.white)
        .monospacedDigit()
        .frame(width: showScore ? 56 : 36, height: 36)
        .background(Color(hex: "3D3354"))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    Color.white.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    var changePickButton: some View {
        Button("CHANGE PICK") {
            showPicks = true
        }
        .dsStyle(.secondary, fullWidth: false)
    }

    private func kickoffLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d'\(daySuffix(date))', ha"
        return formatter.string(from: date).uppercased()
    }

    private func daySuffix(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        switch day {
        case 1, 21, 31: return "ST"
        case 2, 22: return "ND"
        case 3, 23: return "RD"
        default: return "TH"
        }
    }
}
