import SwiftUI

// MARK: - MyPickCard Previews

private func makeFixture(
    teamId: Int = 42,
    status: FixtureStatus,
    homeScore: Int? = nil,
    awayScore: Int? = nil
) -> Fixture {
    Fixture(
        id: 1,
        gameweekId: 30,
        homeTeamId: teamId,
        homeTeamName: "Arsenal",
        homeTeamShort: "ARS",
        homeTeamLogo: nil,
        awayTeamId: 50,
        awayTeamName: "Chelsea",
        awayTeamShort: "CHE",
        awayTeamLogo: nil,
        kickoffAt: Date(),
        status: status,
        homeScore: homeScore,
        awayScore: awayScore
    )
}

private func makePick(result: PickResult = .pending) -> MemberPick {
    MemberPick(
        userId: "user-1",
        teamName: "Arsenal",
        result: result,
        isLocked: true,
        gameweekId: 30,
        fixtureId: 1,
        teamId: 42
    )
}

#Preview("Live - Surviving") {
    MyPickCard(
        pick: makePick(),
        fixture: makeFixture(status: .firstHalf, homeScore: 2, awayScore: 0),
        isSurviving: true
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Live - Losing") {
    MyPickCard(
        pick: makePick(),
        fixture: makeFixture(status: .secondHalf, homeScore: 0, awayScore: 1),
        isSurviving: false
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("FT - Survived") {
    MyPickCard(
        pick: makePick(result: .survived),
        fixture: makeFixture(status: .fullTime, homeScore: 2, awayScore: 1),
        isSurviving: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("FT - Eliminated") {
    MyPickCard(
        pick: makePick(result: .eliminated),
        fixture: makeFixture(status: .fullTime, homeScore: 0, awayScore: 2),
        isSurviving: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Not Started") {
    MyPickCard(
        pick: makePick(),
        fixture: makeFixture(status: .notStarted),
        isSurviving: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
