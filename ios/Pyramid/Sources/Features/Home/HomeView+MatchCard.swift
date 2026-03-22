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
                kickoff: fixture.kickoffAt
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
        ZStack {
            matchCardBackground
            VStack(spacing: Theme.Spacing.s40) {
                Text("NO PICK YET")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(
                        Color.white.opacity(0.4)
                    )
                Text("Make your pick")
                    .font(Theme.Typography.h2)
                    .foregroundStyle(.white)
                changPickPill
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
        kickoff: Date?
    ) -> some View {
        VStack(spacing: Theme.Spacing.s30) {
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

            Text("YOUR PICK")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )

            Text(pickedTeam)
                .font(Theme.Typography.h2)
                .foregroundStyle(.white)

            vsCircle

            Text(opponent)
                .font(Theme.Typography.h3)
                .foregroundStyle(.white)

            if let kickoff {
                Text(kickoffLabel(kickoff))
                    .font(Theme.Typography.overline)
                    .foregroundStyle(
                        Color.white.opacity(0.4)
                    )
            }

            changPickPill
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var vsCircle: some View {
        Text("vs")
            .font(Theme.Typography.label01)
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Color(hex: "3D3354"))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(
                        Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
    }

    private var changPickPill: some View {
        Text("CHANGE PICK")
            .font(Theme.Typography.label01)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.s50)
            .padding(.vertical, Theme.Spacing.s20)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
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
