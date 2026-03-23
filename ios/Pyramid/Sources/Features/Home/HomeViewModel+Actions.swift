import Foundation

// MARK: - Countdown Timer

extension HomeViewModel {
    func startCountdown() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.updateCountdown()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopCountdown() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func updateCountdown() {
        let deadline: Date
        #if DEBUG
        if DebugGameweekOverride.current == .upcoming {
            deadline = DebugGameweekOverride.fakeDeadline
        } else if DebugGameweekOverride.isActive {
            countdown = .zero
            return
        } else {
            guard let real = homeData?.gameweek?.deadlineAt
            else {
                countdown = .zero
                return
            }
            deadline = real
        }
        #else
        guard let real = homeData?.gameweek?.deadlineAt
        else {
            countdown = .zero
            return
        }
        deadline = real
        #endif
        let remaining = deadline.timeIntervalSinceNow
        guard remaining > 0 else {
            // Countdown just expired — refresh data to get
            // latest gameweek status (in progress / finished)
            if !countdown.isExpired {
                Task { await load() }
            }
            countdown = .zero
            return
        }
        let totalSec = Int(remaining)
        let days = totalSec / 86400
        let hours = (totalSec % 86400) / 3600
        let minutes = (totalSec % 3600) / 60
        let seconds = totalSec % 60
        countdown = CountdownComponents(
            days: "\(days)",
            hours: String(format: "%02d", hours),
            minutes: String(format: "%02d", minutes),
            seconds: String(format: "%02d", seconds),
            isExpired: false
        )
    }
}

// MARK: - Gameweek Switching

extension HomeViewModel {
    func selectGameweek(_ gw: Gameweek) {
        selectedGameweek = gw
        if gw.id == homeData?.gameweek?.id {
            selectedGwPicks = []
            return
        }
        Task { await fetchGameweekPicks(gw) }
    }

    private func fetchGameweekPicks(
        _ gw: Gameweek
    ) async {
        guard let data = homeData else { return }
        let userId: String
        do {
            userId = try await SupabaseDependency.shared
                .client.auth.session.user.id.uuidString
        } catch { return }

        let leagueIds = data.leagues.map(\.id)
        let leagueNames = Dictionary(
            uniqueKeysWithValues: data.leagues.map {
                ($0.id, $0.name)
            }
        )
        do {
            selectedGwPicks = try await homeService
                .fetchPicksForGameweek(
                    userId: userId,
                    gameweek: gw,
                    leagueIds: leagueIds,
                    leagueNames: leagueNames
                )
        } catch {
            Log.home.error(
                "GW pick fetch failed: \(error)"
            )
        }
    }
}

// MARK: - Polling

extension HomeViewModel {
    func startPolling() {
        stopPolling()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(
                    nanoseconds: 60_000_000_000
                )
                guard !Task.isCancelled,
                      let self
                else { return }
                guard self.hasLiveFixtures else { return }
                await self.refreshFixtures()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func updatePolling() {
        if hasLiveFixtures {
            startPolling()
        } else {
            stopPolling()
        }
    }

    private func refreshFixtures() async {
        guard let data = homeData,
              let gameweek = data.gameweek
        else { return }
        do {
            let fresh = try await homeService
                .fetchFixtures(gameweekId: gameweek.id)
            let map = Dictionary(
                uniqueKeysWithValues: fresh.map {
                    ($0.id, $0)
                }
            )
            homeData = HomeData(
                leagues: data.leagues,
                gameweek: data.gameweek,
                picks: data.picks,
                memberStatuses: data.memberStatuses,
                fixtures: map,
                lastGwResults: data.lastGwResults,
                allGameweeks: data.allGameweeks,
                playerCounts: data.playerCounts
            )
            updatePolling()
        } catch {
            Log.home.error(
                "Fixture refresh failed: \(error)"
            )
        }
    }
}
