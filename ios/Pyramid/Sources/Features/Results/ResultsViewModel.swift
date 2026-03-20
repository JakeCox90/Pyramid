import SwiftUI

// MARK: - Round Result Model

struct RoundResult: Identifiable {
    let gameweek: Gameweek
    let picks: [RoundPickRow]
    let fixtures: [Fixture]

    var id: Int { gameweek.id }

    var survivedCount: Int {
        picks.filter { $0.result == .survived }.count
    }

    var eliminatedCount: Int {
        picks.filter { $0.result == .eliminated }.count
    }

    var voidCount: Int {
        picks.filter { $0.result == .void }.count
    }

    func fixture(for fixtureId: Int) -> Fixture? {
        fixtures.first { $0.id == fixtureId }
    }
}

// MARK: - ViewModel

@MainActor
final class ResultsViewModel: ObservableObject {
    @Published var rounds: [RoundResult] = []
    @Published var expandedRoundId: Int?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let leagueId: String
    let season: Int

    private let resultsService: ResultsServiceProtocol

    init(
        leagueId: String,
        season: Int,
        resultsService: ResultsServiceProtocol = ResultsService()
    ) {
        self.leagueId = leagueId
        self.season = season
        self.resultsService = resultsService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let gameweeksFetch = resultsService
                .fetchFinishedGameweeks(season: season)
            async let picksFetch = resultsService
                .fetchSettledPicks(leagueId: leagueId)
            let (gameweeks, allPicks) = try await (
                gameweeksFetch, picksFetch
            )

            let gameweekIds = gameweeks.map(\.id)
            let fixtures = try await resultsService
                .fetchFixtures(gameweekIds: gameweekIds)

            let picksByGw = Dictionary(
                grouping: allPicks,
                by: \.gameweekId
            )
            let fixturesByGw = Dictionary(
                grouping: fixtures,
                by: \.gameweekId
            )

            rounds = gameweeks.compactMap { gw in
                guard let gwPicks = picksByGw[gw.id],
                      !gwPicks.isEmpty else {
                    return nil
                }
                return RoundResult(
                    gameweek: gw,
                    picks: gwPicks.sorted { lhs, rhs in
                        lhs.result.sortOrder < rhs.result.sortOrder
                    },
                    fixtures: fixturesByGw[gw.id] ?? []
                )
            }
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func toggleRound(_ roundId: Int) {
        if expandedRoundId == roundId {
            expandedRoundId = nil
        } else {
            expandedRoundId = roundId
        }
    }
}

// MARK: - PickResult Sort Order

private extension PickResult {
    var sortOrder: Int {
        switch self {
        case .eliminated: return 0
        case .survived:   return 1
        case .void:       return 2
        case .pending:    return 3
        }
    }
}
