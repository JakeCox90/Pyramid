import SwiftUI
import UIKit

@MainActor
final class PicksViewModel: ObservableObject {
    @Published var gameweek: Gameweek?
    @Published var fixtures: [Fixture] = []
    /// All fixtures (including started) for GW lock detection
    private var allFixtures: [Fixture] = []
    @Published var currentPick: Pick?
    @Published var usedTeamIds: Set<Int> = []
    @Published var usedTeamNames: [String] = []
    /// Maps team ID → gameweek round number it was used in
    @Published var usedTeamRounds: [Int: Int] = [:]
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
        #if DEBUG
        if DebugGameweekOverride.isActive {
            switch DebugGameweekOverride.current {
            case .none:
                break
            case .upcoming:
                return "Deadline in 3d 8h"
            case .inProgress:
                return "Deadline passed — gameweek in progress"
            case .finished:
                return "Gameweek complete"
            }
        }
        #endif
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
            allFixtures = try await fixturesFetch
            #if DEBUG
            if DebugGameweekOverride.isActive,
               DebugGameweekOverride.current == .upcoming {
                // Show all fixtures so pick buttons can be tested
                fixtures = allFixtures
            } else {
                fixtures = allFixtures.filter {
                    $0.status == .notStarted
                }
            }
            #else
            fixtures = allFixtures.filter {
                $0.status == .notStarted
            }
            #endif
            currentPick = try await pickFetch
            let usedTeams = try await usedTeamsFetch
            usedTeamIds = Set(usedTeams.keys)
            usedTeamNames = usedTeams.values.map(\.teamName)
            usedTeamRounds = usedTeams.mapValues(\.roundNumber)
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
            #if DEBUG
            if DebugGameweekOverride.current == .upcoming {
                // Simulate a successful pick locally — the
                // backend would reject because the real deadline
                // has passed, but we want to test the UI flow.
                try await Task.sleep(nanoseconds: 300_000_000)
                let fakePick = Pick(
                    id: UUID().uuidString,
                    leagueId: leagueId,
                    userId: "debug",
                    gameweekId: gameweek?.id ?? 0,
                    fixtureId: fixtureId,
                    teamId: teamId,
                    teamName: teamName,
                    isLocked: false,
                    result: .pending,
                    submittedAt: Date()
                )
                currentPick = fakePick
                DebugGameweekOverride.setFakePick(
                    leagueId: leagueId,
                    teamId: teamId,
                    teamName: teamName,
                    fixtureId: fixtureId
                )
                isSubmitting = false
                submittingTeamId = nil
                pickConfirmed = true
                return
            }
            #endif
            let response = try await pickService.submitPick(
                leagueId: leagueId,
                fixtureId: fixtureId,
                teamId: teamId,
                teamName: teamName
            )
            if let gw = gameweek {
                currentPick = try await pickService.fetchMyPick(leagueId: leagueId, gameweekId: gw.id)
            }
            pickConfirmed = true
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

    /// Rules §3.3: once the first fixture of the GW kicks off,
    /// ALL picks are locked — no new picks or changes allowed.
    var isGameweekLocked: Bool {
        #if DEBUG
        if DebugGameweekOverride.isActive {
            return DebugGameweekOverride.isLocked
        }
        #endif
        return allFixtures.contains {
            $0.status.isLive || $0.status.isFinished
        }
    }

    func isFixtureLocked(_ fixture: Fixture) -> Bool {
        #if DEBUG
        if DebugGameweekOverride.isActive {
            return DebugGameweekOverride.isLocked
        }
        #endif
        // If any GW fixture has kicked off, everything is locked
        if isGameweekLocked { return true }
        // Individual fixture check
        return fixture.status.isLive
            || fixture.status.isFinished
            || (currentPick?.isLocked == true
                && currentPick?.fixtureId == fixture.id)
    }
}
