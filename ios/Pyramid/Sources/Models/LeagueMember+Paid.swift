import Foundation

// MARK: - LeagueMember paid-league additions
//
// Extension to avoid merge conflicts with branches that also touch LeagueMember.swift.

extension LeagueMember {
    /// Pseudonym assigned when the member joined a paid league.
    var pseudonym: String? { paidExtras?.pseudonym }
    /// Final finishing position (1-indexed) once the paid league is complete.
    var finishingPosition: Int? { paidExtras?.finishingPosition }
    /// Prize amount in pence, populated after settlement.
    var prizePence: Int? { paidExtras?.prizePence }

    // Paid extras are decoded separately and injected at the call site.
    // We store them via associated-value key on the member id.
    internal var paidExtras: PaidMemberExtras? {
        PaidMemberExtras.store[id]
    }
}

// MARK: - PaidMemberExtras

/// Lightweight store for paid-league data that is fetched alongside standings.
/// Keyed by `LeagueMember.id`.
struct PaidMemberExtras: Codable, Sendable {
    let pseudonym: String?
    let finishingPosition: Int?
    let prizePence: Int?

    enum CodingKeys: String, CodingKey {
        case pseudonym
        case finishingPosition = "finishing_position"
        case prizePence = "prize_pence"
    }

    // Simple in-memory store populated by the standings service.
    // Not persisted; refreshed on every load() call.
    @MainActor static var store: [String: PaidMemberExtras] = [:]
}
