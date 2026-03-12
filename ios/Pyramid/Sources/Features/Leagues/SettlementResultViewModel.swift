import SwiftUI

// MARK: - Data Model

struct SettlementResultData {
    let result: PickResult
    let teamName: String
    let score: String
    let gameweekNumber: Int
    let leagueName: String
    let playersRemaining: Int
    let gameweeksLasted: Int
}

// MARK: - ViewModel

@MainActor
final class SettlementResultViewModel: ObservableObject {
    @Published var resultData: SettlementResultData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let leagueId: String
    let gameweekId: Int

    private let pickService: PickServiceProtocol
    private let standingsService: StandingsServiceProtocol
    private let leagueService: LeagueServiceProtocol

    init(
        leagueId: String,
        gameweekId: Int,
        pickService: PickServiceProtocol = PickService(),
        standingsService: StandingsServiceProtocol = StandingsService(),
        leagueService: LeagueServiceProtocol = LeagueService()
    ) {
        self.leagueId = leagueId
        self.gameweekId = gameweekId
        self.pickService = pickService
        self.standingsService = standingsService
        self.leagueService = leagueService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let pickFetch = pickService.fetchMyPick(
                leagueId: leagueId,
                gameweekId: gameweekId
            )
            async let membersFetch = standingsService.fetchMembers(leagueId: leagueId)
            async let leaguesFetch = leagueService.fetchMyLeagues()

            let (pick, members, leagues) = try await (pickFetch, membersFetch, leaguesFetch)

            guard let pick else {
                errorMessage = NSLocalizedString(
                    "settlement.error.no_pick",
                    value: "No pick found for this gameweek.",
                    comment: "Error when no pick data is found for the settlement screen"
                )
                isLoading = false
                return
            }

            let leagueName = leagues.first(where: { $0.id == leagueId })?.name ?? ""
            let activePlayers = members.filter { $0.status == .active }.count
            let score = await fetchScore(for: pick)

            resultData = SettlementResultData(
                result: pick.result,
                teamName: pick.teamName,
                score: score,
                gameweekNumber: gameweekId,
                leagueName: leagueName,
                playersRemaining: activePlayers,
                gameweeksLasted: gameweekId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Private

    private func fetchScore(for pick: Pick) async -> String {
        do {
            let fixtures = try await pickService.fetchFixtures(for: gameweekId)
            if let fixture = fixtures.first(where: { $0.id == pick.fixtureId }),
               let home = fixture.homeScore,
               let away = fixture.awayScore {
                return "\(home) - \(away)"
            }
        } catch {
            Log.picks.warning("Settlement score fetch failed: \(error.localizedDescription)")
        }
        return ""
    }
}
