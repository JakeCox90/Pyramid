import SwiftUI

@MainActor
final class LeagueDetailViewModel: ObservableObject {
    @Published var members: [LeagueMember] = []
    @Published var lockedPicks: [String: MemberPick] = [:]  // keyed by userId
    @Published var currentGameweek: Gameweek?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let league: League

    private let standingsService: StandingsServiceProtocol
    private let pickService: PickServiceProtocol

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
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func pick(for member: LeagueMember) -> MemberPick? {
        lockedPicks[member.userId]
    }

    func isDeadlinePassed() -> Bool {
        guard let deadline = currentGameweek?.deadlineAt else { return false }
        return deadline <= Date()
    }
}
