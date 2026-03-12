import SwiftUI

@MainActor
final class LeagueDetailViewModel: ObservableObject {
    @Published var members: [LeagueMember] = []
    @Published var lockedPicks: [String: MemberPick] = [:]  // keyed by userId
    @Published var currentGameweek: Gameweek?
    @Published var fixtures: [Int: Fixture] = [:]  // keyed by fixture ID
    @Published var isLoading = false
    @Published var errorMessage: String?

    let league: League

    private let standingsService: StandingsServiceProtocol
    private let pickService: PickServiceProtocol
    private var pollingTask: Task<Void, Never>?

    var sortedMembers: [LeagueMember] {
        members.sorted {
            if $0.status.sortOrder != $1.status.sortOrder {
                return $0.status.sortOrder < $1.status.sortOrder
            }
            // Within eliminated: sort by eliminatedInGameweekId descending (most recent first)
            if $0.status == .eliminated && $1.status == .eliminated {
                let gwA = $0.eliminatedInGameweekId ?? 0
                let gwB = $1.eliminatedInGameweekId ?? 0
                return gwA > gwB
            }
            return $0.profiles.displayLabel < $1.profiles.displayLabel
        }
    }

    var activeCount: Int {
        members.filter { $0.status == .active }.count
    }

    var eliminatedCount: Int {
        members.filter { $0.status == .eliminated }.count
    }

    var winnerCount: Int {
        members.filter { $0.status == .winner }.count
    }

    var winners: [LeagueMember] {
        members.filter { $0.status == .winner }
    }

    var isCompleted: Bool {
        league.status == .completed
    }

    var hasLiveFixtures: Bool {
        fixtures.values.contains { $0.status.isLive }
    }

    @Published var currentUserId: String?

    var myPick: MemberPick? {
        guard let userId = currentUserId else { return nil }
        return lockedPicks[userId]
    }

    var myFixture: Fixture? {
        guard let pick = myPick else { return nil }
        return fixtures[pick.fixtureId]
    }

    var isSurviving: Bool? {
        guard let pick = myPick, let fixture = myFixture else { return nil }
        guard let homeScore = fixture.homeScore, let awayScore = fixture.awayScore else { return nil }
        if pick.teamId == fixture.homeTeamId {
            return homeScore >= awayScore
        } else if pick.teamId == fixture.awayTeamId {
            return awayScore >= homeScore
        }
        return nil
    }

    init(
        league: League,
        standingsService: StandingsServiceProtocol = StandingsService(),
        pickService: PickServiceProtocol = PickService()
    ) {
        self.league = league
        self.standingsService = standingsService
        self.pickService = pickService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            if currentUserId == nil {
                currentUserId = try? await SupabaseDependency.shared.client.auth.session.user.id.uuidString
            }
            async let membersFetch = standingsService.fetchMembers(leagueId: league.id)
            async let gameweekFetch = pickService.fetchCurrentGameweek()
            let (fetchedMembers, gameweek) = try await (membersFetch, gameweekFetch)
            members = fetchedMembers
            currentGameweek = gameweek
            let picks = try await standingsService.fetchLockedPicks(
                leagueId: league.id,
                gameweekId: gameweek.id
            )
            lockedPicks = Dictionary(uniqueKeysWithValues: picks.map { ($0.userId, $0) })
            if isDeadlinePassed() {
                try await refreshFixtures()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func pick(for member: LeagueMember) -> MemberPick? {
        lockedPicks[member.userId]
    }

    func fixture(for pick: MemberPick) -> Fixture? {
        fixtures[pick.fixtureId]
    }

    func isDeadlinePassed() -> Bool {
        guard let deadline = currentGameweek?.deadlineAt else { return false }
        return deadline <= Date()
    }

    // MARK: - Polling

    func startPolling() {
        guard isDeadlinePassed() else { return }
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if !self.hasLiveFixtures {
                    return
                }
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                if Task.isCancelled { return }
                await self.silentRefreshFixtures()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @discardableResult
    func refreshFixtures() async throws -> [Fixture] {
        guard let gameweek = currentGameweek else { return [] }
        let fetched = try await pickService.fetchFixtures(for: gameweek.id)
        fixtures = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
        return fetched
    }

    private func silentRefreshFixtures() async {
        do {
            try await refreshFixtures()
            if !hasLiveFixtures {
                stopPolling()
            }
        } catch {
            Log.picks.warning("Live score refresh failed: \(error.localizedDescription)")
        }
    }
}
