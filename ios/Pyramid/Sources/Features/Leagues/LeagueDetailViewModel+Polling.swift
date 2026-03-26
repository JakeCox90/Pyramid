import SwiftUI

// MARK: - Polling & Fixture Refresh

extension LeagueDetailViewModel {

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

    func silentRefreshFixtures() async {
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
