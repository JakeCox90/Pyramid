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
    var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            matchupArea
            pickTeamDivider
            pickButtons
        }
        .frame(height: 212)
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r50)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r50)
                .stroke(
                    Color.white.opacity(0.1), lineWidth: 1
                )
        )
    }
}

// MARK: - Card Background

extension FixturePickRow {
    var cardBackground: some View {
        ZStack {
            Color(hex: "241E31")
            LinearGradient(
                colors: [
                    Color(hex: "5E4E81"),
                    Color(hex: "2D253D")
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

// MARK: - Matchup Area

extension FixturePickRow {
    var matchupArea: some View {
        HStack(spacing: 0) {
            teamSide(
                teamId: fixture.homeTeamId,
                teamName: fixture.homeTeamName,
                logoURL: fixture.homeTeamLogo
            )

            vsLabel
                .frame(width: 40)

            teamSide(
                teamId: fixture.awayTeamId,
                teamName: fixture.awayTeamName,
                logoURL: fixture.awayTeamLogo
            )
        }
        .padding(.horizontal, Theme.Spacing.s60)
        .padding(.top, Theme.Spacing.s30)
    }

    @ViewBuilder
    func teamSide(
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
                size: 74
            )
            .opacity(isUsed ? 0.2 : 1.0)

            Text(teamName.uppercased())
                .font(
                    Theme.Typography.caption1.bold()
                )
                .foregroundStyle(Color.white)
                .opacity(isUsed ? 0.2 : 0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    var vsLabel: some View {
        Group {
            if fixture.status.isLive
                || fixture.status.isFinished,
               let home = fixture.homeScore,
               let away = fixture.awayScore {
                Text("\(home) - \(away)")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
            } else {
                Text("VS")
                    .font(
                        Theme.Typography.caption1.bold()
                    )
                    .foregroundStyle(Color.white)
                    .tracking(1)
            }
        }
    }
}

// MARK: - Pick Team Divider

extension FixturePickRow {
    var pickTeamDivider: some View {
        HStack(spacing: 0) {
            dividerLine
            Text("PICK TEAM")
                .font(
                    Theme.Typography.caption1.bold()
                )
                .foregroundStyle(
                    Color.white.opacity(0.4)
                )
                .tracking(1)
                .padding(.horizontal, Theme.Spacing.s30)
            dividerLine
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s20)
    }

    var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(height: 1)
    }
}
