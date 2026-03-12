import XCTest
@testable import Pyramid

@MainActor
final class LeagueDetailViewModelTests: XCTestCase {

    // MARK: - Fixtures

    static let league = League(
        id: "league-1", name: "Sunday Heroes", joinCode: "ABC123",
        type: .free, status: .active, season: 2025,
        createdAt: Date()
    )

    static let activeMembers: [LeagueMember] = [
        LeagueMember(id: "m1", userId: "u1", status: .active, joinedAt: Date(),
                     eliminatedAt: nil, eliminatedInGameweekId: nil,
                     profiles: .init(username: "alice", displayName: "Alice")),
        LeagueMember(id: "m2", userId: "u2", status: .eliminated, joinedAt: Date(),
                     eliminatedAt: Date(), eliminatedInGameweekId: 5,
                     profiles: .init(username: "bob", displayName: "Bob"))
    ]

    // MARK: - load()

    func testLoadSuccessSetsMembers() async {
        let mock = MockStandingsService(members: Self.activeMembers)
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.members.count, 2)
    }

    func testLoadFailureSetsErrorMessage() async {
        let mock = MockStandingsService(shouldFail: true)
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.members.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadSetsCurrentGameweek() async {
        let mock = MockStandingsService(members: Self.activeMembers)
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        XCTAssertNotNil(vm.currentGameweek)
        XCTAssertEqual(vm.currentGameweek?.id, MockPickService.stubGameweek.id)
    }

    func testLoadSetsLockedPicks() async {
        let lockedPick = MemberPick(
            userId: "u1", teamName: "Arsenal",
            result: .pending, isLocked: true, gameweekId: 29,
            fixtureId: 12345, teamId: 42
        )
        let mock = MockStandingsService(members: Self.activeMembers, lockedPicks: [lockedPick])
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        XCTAssertNotNil(vm.pick(for: Self.activeMembers[0]))
        XCTAssertNil(vm.pick(for: Self.activeMembers[1]))
    }

    // MARK: - sortedMembers

    func testActiveMembersBeforeEliminated() async {
        let mock = MockStandingsService(members: Self.activeMembers)
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        let sorted = vm.sortedMembers
        XCTAssertEqual(sorted.first?.status, .active)
        XCTAssertEqual(sorted.last?.status, .eliminated)
    }

    func testEliminatedSortedByGameweekDescending() async {
        let e1 = LeagueMember(id: "e1", userId: "eu1", status: .eliminated, joinedAt: Date(),
                              eliminatedAt: Date(), eliminatedInGameweekId: 3,
                              profiles: .init(username: "carol", displayName: "Carol"))
        let e2 = LeagueMember(id: "e2", userId: "eu2", status: .eliminated, joinedAt: Date(),
                              eliminatedAt: Date(), eliminatedInGameweekId: 7,
                              profiles: .init(username: "dave", displayName: "Dave"))
        let mock = MockStandingsService(members: [e1, e2])
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        let sorted = vm.sortedMembers
        XCTAssertEqual(sorted.first?.eliminatedInGameweekId, 7)
        XCTAssertEqual(sorted.last?.eliminatedInGameweekId, 3)
    }

    // MARK: - activeCount / eliminatedCount

    func testActiveCount() async {
        let mock = MockStandingsService(members: Self.activeMembers)
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        XCTAssertEqual(vm.activeCount, 1)
        XCTAssertEqual(vm.eliminatedCount, 1)
    }

    // MARK: - isDeadlinePassed

    func testDeadlinePassedReturnsTrueWhenInPast() async {
        let pastGw = Gameweek(
            id: 29, season: 2025, roundNumber: 29, name: "Gameweek 29",
            deadlineAt: Date().addingTimeInterval(-3600),
            isCurrent: true, isFinished: false
        )
        let mock = MockStandingsService(members: [])
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService(gameweek: pastGw)
        )

        await vm.load()

        XCTAssertTrue(vm.isDeadlinePassed())
    }

    func testDeadlinePassedReturnsFalseWhenInFuture() async {
        let mock = MockStandingsService(members: [])
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: mock,
            pickService: MockPickService()
        )

        await vm.load()

        XCTAssertFalse(vm.isDeadlinePassed())
    }

    func testDeadlinePassedReturnsFalseWithNoGameweek() {
        let vm = LeagueDetailViewModel(
            league: Self.league,
            standingsService: MockStandingsService(members: []),
            pickService: MockPickService()
        )
        XCTAssertFalse(vm.isDeadlinePassed())
    }
}

// MARK: - Mock

final class MockStandingsService: StandingsServiceProtocol {
    private let members: [LeagueMember]
    private let lockedPicks: [MemberPick]
    private let shouldFail: Bool

    init(
        members: [LeagueMember] = [],
        lockedPicks: [MemberPick] = [],
        shouldFail: Bool = false
    ) {
        self.members = members
        self.lockedPicks = lockedPicks
        self.shouldFail = shouldFail
    }

    func fetchMembers(leagueId: String) async throws -> [LeagueMember] {
        if shouldFail { throw URLError(.badServerResponse) }
        return members
    }

    func fetchLockedPicks(leagueId: String, gameweekId: Int) async throws -> [MemberPick] {
        if shouldFail { throw URLError(.badServerResponse) }
        return lockedPicks
    }
}
