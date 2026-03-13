import XCTest
@testable import Pyramid

@MainActor
final class ProfileViewModelTests: XCTestCase {

    // MARK: - signOut

    func testSignOutSuccessReturnsTrue() async {
        let vm = ProfileViewModel(
            authService: MockProfileAuthService(),
            profileService: MockProfileService()
        )

        let result = await vm.signOut()

        XCTAssertTrue(result)
        XCTAssertFalse(vm.isSigningOut)
        XCTAssertNil(vm.errorMessage)
    }

    func testSignOutFailureSetsErrorMessage() async {
        let vm = ProfileViewModel(
            authService: MockProfileAuthService(shouldFail: true),
            profileService: MockProfileService()
        )

        let result = await vm.signOut()

        XCTAssertFalse(result)
        XCTAssertFalse(vm.isSigningOut)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - loadStats

    func testLoadStatsSuccess() async {
        let expected = ProfileStats(
            totalLeaguesJoined: 3,
            wins: 1,
            totalPicksMade: 15,
            longestSurvivalStreak: 5,
            activeStreaks: [
                LeagueStreak(
                    id: "league-1",
                    leagueName: "Test League",
                    currentStreak: 3
                )
            ],
            leagueHistory: [
                CompletedLeague(
                    id: "league-2",
                    leagueName: "Old League",
                    result: .winner,
                    eliminatedGameweek: nil,
                    season: 2025
                )
            ]
        )

        let vm = ProfileViewModel(
            authService: MockProfileAuthService(),
            profileService: MockProfileService(stats: expected)
        )

        await vm.loadStats()

        XCTAssertEqual(vm.stats, expected)
        XCTAssertFalse(vm.isLoadingStats)
        XCTAssertNil(vm.errorMessage)
    }

    func testLoadStatsFailureSetsError() async {
        let vm = ProfileViewModel(
            authService: MockProfileAuthService(),
            profileService: MockProfileService(shouldFail: true)
        )

        await vm.loadStats()

        XCTAssertEqual(vm.stats, .empty)
        XCTAssertFalse(vm.isLoadingStats)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testLoadStatsStartsEmpty() {
        let vm = ProfileViewModel(
            authService: MockProfileAuthService(),
            profileService: MockProfileService()
        )

        XCTAssertEqual(vm.stats, .empty)
        XCTAssertFalse(vm.isLoadingStats)
    }
}

// MARK: - Mocks

private final class MockProfileAuthService: AuthServiceProtocol {
    var shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String) async throws {}

    func signOut() async throws {
        if shouldFail { throw URLError(.badServerResponse) }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {}
    func signInWithGoogle() async throws {}
}

private final class MockProfileService: ProfileServiceProtocol {
    let stats: ProfileStats
    let shouldFail: Bool

    init(stats: ProfileStats = .empty, shouldFail: Bool = false) {
        self.stats = stats
        self.shouldFail = shouldFail
    }

    func fetchProfileStats() async throws -> ProfileStats {
        if shouldFail {
            throw ProfileServiceError.fetchFailed("Mock error")
        }
        return stats
    }
}
