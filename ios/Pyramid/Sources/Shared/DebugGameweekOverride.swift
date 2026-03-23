#if DEBUG
import Foundation

/// Debug-only override for the gameweek phase.
/// Both HomeViewModel and PicksViewModel read this to
/// simulate different gameweek states during development.
enum DebugGameweekOverride {
    enum Phase: String, CaseIterable {
        case none = "Live Data"
        case upcoming = "Not Started"
        case inProgress = "In Progress"
        case finished = "Finished"
    }

    /// Persisted across app launches via UserDefaults.
    static var current: Phase {
        get {
            guard let raw = UserDefaults.standard.string(
                forKey: "debug_gameweek_phase"
            ) else { return .none }
            return Phase(rawValue: raw) ?? .none
        }
        set {
            let old = current
            UserDefaults.standard.set(
                newValue.rawValue,
                forKey: "debug_gameweek_phase"
            )
            if old == .upcoming, newValue != .upcoming {
                resetFakeDeadline()
            }
        }
    }

    /// Returns true when the override forces the GW to be locked
    /// (in-progress or finished).
    static var isLocked: Bool {
        switch current {
        case .none: return false
        case .upcoming: return false
        case .inProgress, .finished: return true
        }
    }

    /// Returns true only when an override is active (not .none).
    static var isActive: Bool {
        current != .none
    }

    /// A fixed fake deadline anchored to the first time it's
    /// accessed after selecting "Not Started". Resets when the
    /// phase changes away from .upcoming.
    static var fakeDeadline: Date {
        let key = "debug_fake_deadline"
        if let stored = UserDefaults.standard.object(forKey: key) as? Date {
            return stored
        }
        let deadline = Date().addingTimeInterval(
            3 * 86400 + 8 * 3600
        )
        UserDefaults.standard.set(deadline, forKey: key)
        return deadline
    }

    /// Clear the anchored deadline so it gets a fresh one
    /// next time "Not Started" is selected.
    static func resetFakeDeadline() {
        UserDefaults.standard.removeObject(
            forKey: "debug_fake_deadline"
        )
    }

    /// Stores a fake pick made during debug so the home
    /// screen can display it after navigating back.
    struct FakePick {
        let leagueId: String
        let teamId: Int
        let teamName: String
        let fixtureId: Int
    }

    private(set) static var fakePicks: [String: FakePick] = [:]

    static func fakePick(
        for leagueId: String
    ) -> FakePick? {
        fakePicks[leagueId]
    }

    static func setFakePick(
        leagueId: String,
        teamId: Int,
        teamName: String,
        fixtureId: Int
    ) {
        fakePicks[leagueId] = FakePick(
            leagueId: leagueId,
            teamId: teamId,
            teamName: teamName,
            fixtureId: fixtureId
        )
    }

    static func clearFakePicks() {
        fakePicks.removeAll()
    }
}
#endif
