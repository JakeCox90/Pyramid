import SwiftUI

@MainActor
final class LeagueDetailViewModel: ObservableObject {
    @Published var members: [LeagueMember] = []
    @Published var lockedPicks: [String: MemberPick] = [:]  // keyed by userId
    @Published var currentGameweek: Gameweek?
    @Published var fixtures: [Int: Fixture] = [:]  // keyed by fixture ID
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activityEvents: [ActivityEvent] = []
    @Published var showAllActivity = false
    @Published var eliminationPick: MemberPick?
    @Published var eliminationFixture: Fixture?
    @Published var eliminationGameweekName: String?
    @Published var isLeaving = false
    @Published var didLeaveLeague = false

    let league: League

    private let standingsService: StandingsServiceProtocol
    let pickService: PickServiceProtocol
    private let activityFeedService: ActivityFeedServiceProtocol
    private let leagueService: LeagueServiceProtocol
    var pollingTask: Task<Void, Never>?

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

    var isRecapAvailable: Bool {
        isDeadlinePassed() && !hasLiveFixtures
    }

    @Published var currentUserId: String?

    var currentUserMember: LeagueMember? {
        guard let userId = currentUserId else { return nil }
        return members.first { $0.userId == userId }
    }

    var isCurrentUserEliminated: Bool {
        currentUserMember?.status == .eliminated
    }

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
        pickService: PickServiceProtocol = PickService(),
        activityFeedService: ActivityFeedServiceProtocol = ActivityFeedService(),
        leagueService: LeagueServiceProtocol = LeagueService()
    ) {
        self.league = league
        self.standingsService = standingsService
        self.pickService = pickService
        self.activityFeedService = activityFeedService
        self.leagueService = leagueService
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
            await loadEliminationData()
            await loadActivityFeed()
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func loadActivityFeed() async {
        do {
            activityEvents = try await activityFeedService
                .fetchActivityEvents(leagueId: league.id)
        } catch {
            Log.picks.warning(
                "Activity feed load failed: \(error.localizedDescription)"
            )
        }
    }

    func loadEliminationData() async {
        guard let member = currentUserMember,
              member.status == .eliminated,
              let eliminationGwId = member.eliminatedInGameweekId
        else { return }

        do {
            let picks = try await standingsService.fetchLockedPicks(
                leagueId: league.id,
                gameweekId: eliminationGwId
            )
            guard let userId = currentUserId,
                  let pick = picks.first(where: { $0.userId == userId })
            else { return }

            let fixtures = try await pickService.fetchFixtures(for: eliminationGwId)
            let fixture = fixtures.first { $0.id == pick.fixtureId }

            eliminationPick = pick
            eliminationFixture = fixture
            eliminationGameweekName = "Gameweek \(eliminationGwId)"
        } catch {
            Log.picks.warning(
                "Elimination data load failed: \(error.localizedDescription)"
            )
        }
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

    // MARK: - Leave League

    func leaveLeague() async {
        isLeaving = true
        do {
            try await leagueService.leaveLeague(leagueId: league.id)
            didLeaveLeague = true
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLeaving = false
    }

}
