#if DEBUG
import SwiftUI

struct MatchCardDemo: View {
    @State private var phase: MatchCard.Phase =
        .preMatch
    @State private var isLocked = false
    @State private var survived: Int = 0

    private var survivedValue: Bool? {
        switch survived {
        case 1: true
        case 2: false
        default: nil
        }
    }

    var body: some View {
        DemoPage {
            MatchCard(
                pickedTeamName: "Arsenal",
                pickedTeamLogo: nil,
                opponentName: "Aston Villa",
                homeTeamName: "Arsenal",
                venue: "Emirates Stadium",
                kickoff: Calendar.current.date(
                    bySettingHour: 15,
                    minute: 0,
                    second: 0,
                    of: Date()
                        .addingTimeInterval(86400)
                ),
                homeScore: phase != .preMatch
                    ? 2 : nil,
                awayScore: phase != .preMatch
                    ? 1 : nil,
                phase: phase,
                survived: phase == .finished
                    ? survivedValue : nil,
                isLocked: isLocked,
                buttonTitle: "CHANGE PICK",
                onButtonTap: isLocked ? nil : {}
            )
        } config: {
            ConfigRow(label: "Phase") {
                Picker("", selection: $phase) {
                    Text("preMatch")
                        .tag(
                            MatchCard.Phase.preMatch
                        )
                    Text("live")
                        .tag(MatchCard.Phase.live)
                    Text("finished")
                        .tag(
                            MatchCard.Phase.finished
                        )
                }
            }
            ConfigDivider()
            ConfigRow(label: "Locked") {
                Toggle("", isOn: $isLocked)
                    .labelsHidden()
            }
            ConfigDivider()
            ConfigRow(label: "Survived") {
                Picker("", selection: $survived) {
                    Text("nil").tag(0)
                    Text("true").tag(1)
                    Text("false").tag(2)
                }
            }
        }
    }
}

struct ResultCardDemo: View {
    var body: some View {
        DemoPageStatic {
            VStack(spacing: Theme.Spacing.s30) {
                ResultCard(
                    homeTeamName: "Liverpool",
                    homeTeamShort: "LIV",
                    homeTeamLogo: nil,
                    awayTeamName: "Everton",
                    awayTeamShort: "EVE",
                    awayTeamLogo: nil,
                    homeScore: 2,
                    awayScore: 1,
                    pickedHome: true,
                    result: .survived
                )
                ResultCard(
                    homeTeamName: "Arsenal",
                    homeTeamShort: "ARS",
                    homeTeamLogo: nil,
                    awayTeamName: "Chelsea",
                    awayTeamShort: "CHE",
                    awayTeamLogo: nil,
                    homeScore: 0,
                    awayScore: 2,
                    pickedHome: true,
                    result: .eliminated
                )
            }
        }
    }
}

struct EliminationCardDemo: View {
    var body: some View {
        DemoPageStatic {
            EliminationCard(
                leagueName: "Sunday League",
                gameweekName: "Gameweek 29",
                pickedTeamName: "Arsenal",
                pickedTeamLogo: nil,
                opponentName: "Aston Villa",
                homeTeamName: "Arsenal",
                homeTeamShort: "ARS",
                homeTeamLogo: nil,
                awayTeamName: "Aston Villa",
                awayTeamShort: "AVL",
                awayTeamLogo: nil,
                homeScore: 0,
                awayScore: 2,
                pickedHome: true
            )
        }
    }
}

struct SurvivalCardDemo: View {
    var body: some View {
        DemoPageStatic {
            SurvivalCard(
                leagueName: "Sunday League",
                gameweekName: "Gameweek 29",
                pickedTeamName: "Liverpool",
                pickedTeamLogo: nil,
                opponentName: "Everton",
                homeTeamName: "Liverpool",
                homeTeamShort: "LIV",
                homeTeamLogo: nil,
                awayTeamName: "Everton",
                awayTeamShort: "EVE",
                awayTeamLogo: nil,
                homeScore: 2,
                awayScore: 1,
                pickedHome: true
            )
        }
    }
}

struct MatchStatsDemo: View {
    var body: some View {
        DemoPageStatic {
            MatchCarouselCardStats(
                fixture: Fixture(
                    id: 1,
                    gameweekId: 20,
                    homeTeamId: 42,
                    homeTeamName: "Arsenal",
                    homeTeamShort: "ARS",
                    homeTeamLogo: nil,
                    awayTeamId: 66,
                    awayTeamName: "Aston Villa",
                    awayTeamShort: "A. Villa",
                    awayTeamLogo: nil,
                    kickoffAt: Date()
                        .addingTimeInterval(86400),
                    status: .notStarted,
                    homeScore: nil,
                    awayScore: nil,
                    venue: "Emirates Stadium",
                    homeWinProb: 0.55,
                    drawProb: 0.25,
                    awayWinProb: 0.20
                ),
                stats: .placeholder,
                onBack: {}
            )
        }
    }
}
#endif
