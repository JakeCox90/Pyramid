import SwiftUI
import UIKit

@MainActor
final class PicksViewModel: ObservableObject {
    @Published var gameweek: Gameweek?
    @Published var fixtures: [Fixture] = []
    @Published var currentPick: Pick?
    @Published var usedTeamIds: Set<Int> = []
    @Published var usedTeamNames: [String] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var submittingTeamId: Int?
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showCelebration = false
    @Published var celebratedTeamId: Int?
    @Published var pickConfirmed = false

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
            async let usedTeamsFetch = pickService.fetchUsedTeams(leagueId: leagueId)
            let allFixtures = try await fixturesFetch
            fixtures = allFixtures.filter {
                $0.status == .notStarted
            }
            currentPick = try await pickFetch
            let usedTeams = try await usedTeamsFetch
            usedTeamIds = Set(usedTeams.keys)
            usedTeamNames = Array(usedTeams.values)
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isLoading = false
    }

    func submitPick(fixtureId: Int, teamId: Int, teamName: String) async {
        guard !isSubmitting else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isSubmitting = true
        submittingTeamId = teamId
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
            celebratedTeamId = teamId
            showCelebration = true
            if let gw = gameweek {
                currentPick = try await pickService.fetchMyPick(leagueId: leagueId, gameweekId: gw.id)
            }
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self?.successMessage = nil
                self?.showCelebration = false
                self?.celebratedTeamId = nil
                self?.pickConfirmed = true
            }
        } catch {
            errorMessage = AppError.from(error).userMessage
        }
        isSubmitting = false
        submittingTeamId = nil
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
        // Trust API status over local time comparison —
        // a fixture is only locked if it's actually live/finished
        // or the user's pick on this fixture is server-locked
        fixture.status.isLive
            || fixture.status.isFinished
            || (currentPick?.isLocked == true
                && currentPick?.fixtureId == fixture.id)
    }
}
