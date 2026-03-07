import SwiftUI

@MainActor
final class PicksViewModel: ObservableObject {
    @Published var gameweek: Gameweek?
    @Published var fixtures: [Fixture] = []
    @Published var currentPick: Pick?
    @Published var usedTeamIds: Set<Int> = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let leagueId: String

    private let pickService: PickServiceProtocol

    var deadlineText: String? {
        guard let deadline = gameweek?.deadlineAt else { return nil }
        let now = Date()
        guard deadline > now else { return "Deadline passed" }
        let interval = deadline.timeIntervalSince(now)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 48 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE dd MMM, HH:mm"
            return "Deadline: \(formatter.string(from: deadline))"
        } else if hours > 0 {
            return "Deadline in \(hours)h \(minutes)m"
        } else {
            return "Deadline in \(minutes)m"
        }
    }

    init(leagueId: String, pickService: PickServiceProtocol = PickService()) {
        self.leagueId = leagueId
        self.pickService = pickService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let gw = try await pickService.fetchCurrentGameweek()
            gameweek = gw
            async let fixturesFetch = pickService.fetchFixtures(for: gw.id)
            async let pickFetch = pickService.fetchMyPick(leagueId: leagueId, gameweekId: gw.id)
            async let usedTeamsFetch = pickService.fetchUsedTeamIds(leagueId: leagueId)
            fixtures = try await fixturesFetch
            currentPick = try await pickFetch
            usedTeamIds = try await usedTeamsFetch
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func submitPick(fixtureId: Int, teamId: Int, teamName: String) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        do {
            let response = try await pickService.submitPick(
                leagueId: leagueId,
                fixtureId: fixtureId,
                teamId: teamId,
                teamName: teamName
            )
            successMessage = "Pick confirmed: \(response.teamName)"
            if let gw = gameweek {
                currentPick = try await pickService.fetchMyPick(leagueId: leagueId, gameweekId: gw.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func isTeamPicked(_ teamId: Int) -> Bool {
        currentPick?.teamId == teamId
    }

    func isTeamUsed(_ teamId: Int) -> Bool {
        // A team used in a previous GW but NOT the current pick is grayed out
        guard let pick = currentPick else {
            return usedTeamIds.contains(teamId)
        }
        // Current pick's team: used but selectable (it's this week's choice)
        if pick.teamId == teamId { return false }
        return usedTeamIds.contains(teamId)
    }

    func isFixtureLocked(_ fixture: Fixture) -> Bool {
        fixture.hasKickedOff || (currentPick?.isLocked == true && currentPick?.fixtureId == fixture.id)
    }
}
