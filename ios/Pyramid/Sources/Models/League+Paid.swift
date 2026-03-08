import Foundation

// MARK: - League paid-league additions
//
// Extension to avoid merge conflicts with branches that also touch League.swift.

extension League {
    /// Non-nil when `type == .paid`. Reflects the paid-league lifecycle phase.
    var paidStatus: PaidLeagueStatus? {
        guard type == .paid else { return nil }
        switch status {
        case .pending:   return .waiting
        case .active:    return .active
        case .completed: return .complete
        case .cancelled: return nil
        }
    }
}
