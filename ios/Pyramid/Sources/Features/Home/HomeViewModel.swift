import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var homeData: HomeData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let homeService: HomeServiceProtocol
    private var pollingTask: Task<Void, Never>?

    init(homeService: HomeServiceProtocol = HomeService()) {
        self.homeService = homeService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            homeData = try await homeService.fetchHomeData()
            updatePolling()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var livePickContexts: [LivePickContext] {
        guard let data = homeData else { return [] }
        let leagueMap = Dictionary(
            uniqueKeysWithValues: data.leagues.map { ($0.id, $0.name) }
        )
        return data.picks.values.compactMap { pick in
            guard let fixture = data.fixtures[pick.fixtureId],
                  fixture.status.isLive,
                  let name = leagueMap[pick.leagueId] else {
                return nil
            }
            return LivePickContext(
                pick: pick,
                fixture: fixture,
                leagueName: name
            )
        }
    }

    var hasLiveFixtures: Bool {
        homeData?.fixtures.values.contains { $0.status.isLive } ?? false
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled, let self else { return }
                guard self.hasLiveFixtures else { return }
                await self.refreshFixtures()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Private

    private func updatePolling() {
        if hasLiveFixtures {
            startPolling()
        } else {
            stopPolling()
        }
    }

    private func refreshFixtures() async {
        guard let data = homeData, let gameweek = data.gameweek else {
            return
        }
        do {
            let fresh = try await homeService.fetchFixtures(
                gameweekId: gameweek.id
            )
            let fixtureMap = Dictionary(
                uniqueKeysWithValues: fresh.map { ($0.id, $0) }
            )
            homeData = HomeData(
                leagues: data.leagues,
                gameweek: data.gameweek,
                picks: data.picks,
                memberStatuses: data.memberStatuses,
                fixtures: fixtureMap
            )
            updatePolling()
        } catch {
            Log.home.error(
                "Fixture refresh failed: \(error.localizedDescription)"
            )
        }
    }
}
