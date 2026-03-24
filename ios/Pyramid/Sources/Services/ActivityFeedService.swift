import Foundation
import Supabase
import SwiftUI

// MARK: - Protocol

protocol ActivityFeedServiceProtocol: Sendable {
    func fetchActivityEvents(
        leagueId: String
    ) async throws -> [ActivityEvent]
}

// MARK: - Implementation

final class ActivityFeedService: ActivityFeedServiceProtocol {
    private let client: SupabaseClient

    init(
        client: SupabaseClient = SupabaseDependency.shared.client
    ) {
        self.client = client
    }

    func fetchActivityEvents(
        leagueId: String
    ) async throws -> [ActivityEvent] {
        async let membersFetch = fetchMembers(leagueId: leagueId)
        async let picksFetch = fetchSettledPicks(leagueId: leagueId)

        let (members, picks) = try await (membersFetch, picksFetch)

        var events: [ActivityEvent] = []
        events.append(contentsOf: deriveJoinEvents(from: members))
        events.append(
            contentsOf: deriveEliminationEvents(from: members)
        )
        events.append(
            contentsOf: derivePickResultEvents(from: picks)
        )
        events.append(
            contentsOf: deriveStreakEvents(from: picks)
        )

        events.sort { $0.timestamp > $1.timestamp }
        return Array(events.prefix(20))
    }

    // MARK: - Queries

    private func fetchMembers(
        leagueId: String
    ) async throws -> [ActivityMember] {
        let members: [ActivityMember] = try await client
            .from("league_members")
            .select("""
                id, user_id, status, joined_at,
                eliminated_at, eliminated_in_gameweek_id,
                profiles(username, display_name)
            """)
            .eq("league_id", value: leagueId)
            .order("joined_at", ascending: false)
            .execute()
            .value
        return members
    }

    private func fetchSettledPicks(
        leagueId: String
    ) async throws -> [ActivityPick] {
        let picks: [ActivityPick] = try await client
            .from("picks")
            .select("""
                id, user_id, team_name, result,
                gameweek_id, submitted_at,
                profiles:user_id(username, display_name)
            """)
            .eq("league_id", value: leagueId)
            .neq("result", value: "pending")
            .order("submitted_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return picks
    }

    // MARK: - Event Derivation

    private func deriveJoinEvents(
        from members: [ActivityMember]
    ) -> [ActivityEvent] {
        members.map { member in
            ActivityEvent(
                id: "joined-\(member.id)",
                type: .joined,
                description: "\(member.displayName) joined the league",
                timestamp: member.joinedAt,
                dotColor: Theme.Color.Status.Info.resting
            )
        }
    }

    private func deriveEliminationEvents(
        from members: [ActivityMember]
    ) -> [ActivityEvent] {
        members.compactMap { member in
            guard
                member.status == "eliminated",
                let eliminatedAt = member.eliminatedAt
            else { return nil }

            let gwText = member.eliminatedInGameweekId
                .map { " in GW\($0)" } ?? ""
            return ActivityEvent(
                id: "eliminated-\(member.id)",
                type: .elimination,
                description: "\(member.displayName) was eliminated\(gwText)",
                timestamp: eliminatedAt,
                dotColor: Theme.Color.Status.Error.resting
            )
        }
    }

    private func derivePickResultEvents(
        from picks: [ActivityPick]
    ) -> [ActivityEvent] {
        picks.compactMap { pick in
            guard pick.result == "survived" else { return nil }
            return ActivityEvent(
                id: "survived-\(pick.id)",
                type: .survived,
                description: "\(pick.displayName) survived with \(pick.teamName)",
                timestamp: pick.submittedAt,
                dotColor: Theme.Color.Status.Success.resting
            )
        }
    }

    private func deriveStreakEvents(
        from picks: [ActivityPick]
    ) -> [ActivityEvent] {
        let survivedByUser = Dictionary(
            grouping: picks.filter { $0.result == "survived" },
            by: \.userId
        )

        return survivedByUser.compactMap { _, userPicks in
            let count = userPicks.count
            guard count >= 3, count.isMultiple(of: 3),
                  let latest = userPicks.first else {
                return nil
            }
            return ActivityEvent(
                id: "streak-\(latest.userId)-\(count)",
                type: .streakMilestone,
                description: "\(latest.displayName) has a \(count) GW survival streak!",
                timestamp: latest.submittedAt,
                dotColor: Theme.Color.Status.Success.resting
            )
        }
    }
}

// MARK: - Internal Models

private struct ActivityMember: Codable {
    let id: String
    let userId: String
    let status: String
    let joinedAt: Date
    let eliminatedAt: Date?
    let eliminatedInGameweekId: Int?
    let profiles: ActivityProfile

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case joinedAt = "joined_at"
        case eliminatedAt = "eliminated_at"
        case eliminatedInGameweekId = "eliminated_in_gameweek_id"
        case profiles
    }

    var displayName: String {
        profiles.displayName ?? profiles.username
    }
}

private struct ActivityPick: Codable {
    let id: String
    let userId: String
    let teamName: String
    let result: String
    let gameweekId: Int
    let submittedAt: Date
    let profiles: ActivityProfile

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamName = "team_name"
        case result
        case gameweekId = "gameweek_id"
        case submittedAt = "submitted_at"
        case profiles
    }

    var displayName: String {
        profiles.displayName ?? profiles.username
    }
}

private struct ActivityProfile: Codable {
    let username: String
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
    }
}
