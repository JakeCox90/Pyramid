import Foundation
import os
import Supabase

// MARK: - Error

enum LeagueServiceError: LocalizedError, Equatable {
    case invalidName
    case invalidCode
    case createFailed(String)
    case joinFailed(String)
    case fetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "League name must be between 3 and 40 characters."
        case .invalidCode:
            return "Join code must be 6 characters."
        case .createFailed(let message):
            return message
        case .joinFailed(let message):
            return message
        case .fetchFailed(let message):
            return message
        }
    }
}

// MARK: - Join query helpers

/// Intermediate type for decoding league_members → leagues join queries.
private struct LeagueMemberRow: Decodable {
    let leagueId: String

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
    }
}

/// Row from leagues query with nested member count.
private struct LeagueWithCountRow: Decodable {
    let id: String
    let name: String
    let joinCode: String
    let type: League.LeagueType
    let status: League.LeagueStatus
    let season: Int
    let createdAt: Date
    let leagueMembers: [AggregateCount]

    enum CodingKeys: String, CodingKey {
        case id, name, type, status, season
        case joinCode = "join_code"
        case createdAt = "created_at"
        case leagueMembers = "league_members"
    }

    func toLeague() -> League {
        var league = League(
            id: id,
            name: name,
            joinCode: joinCode,
            type: type,
            status: status,
            season: season,
            createdAt: createdAt
        )
        league.memberCount = leagueMembers.first?.count ?? 0
        return league
    }
}

private struct AggregateCount: Decodable {
    let count: Int
}

/// Row from league_members with embedded league + member count (single-query fetch).
private struct MemberWithLeagueRow: Decodable {
    let leagues: LeagueWithCountRow
}

// MARK: - Protocol

protocol LeagueServiceProtocol: Sendable {
    func createLeague(name: String) async throws -> CreateLeagueResponse
    func previewLeague(code: String) async throws -> LeaguePreview
    func joinLeague(code: String) async throws -> JoinLeagueResponse
    func fetchMyLeagues() async throws -> [League]
    func fetchOpenLeagues() async throws -> [BrowseLeague]
}

// MARK: - Implementation

final class LeagueService: LeagueServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func createLeague(name: String) async throws -> CreateLeagueResponse {
        do {
            Log.leagues.info("Creating league: \(name)")
            let response: CreateLeagueResponse = try await client.functions.invoke(
                "create-league",
                options: FunctionInvokeOptions(body: ["name": name])
            )
            Log.leagues.info("League created: \(response.leagueId)")
            return response
        } catch {
            Log.leagues.error("League creation failed: \(error)")
            throw LeagueServiceError.createFailed(error.localizedDescription)
        }
    }

    func previewLeague(code: String) async throws -> LeaguePreview {
        do {
            let preview: LeaguePreview = try await client.functions.invoke(
                "join-league",
                options: FunctionInvokeOptions(
                    method: .get,
                    query: [URLQueryItem(name: "code", value: code)]
                )
            )
            return preview
        } catch {
            throw LeagueServiceError.joinFailed(error.localizedDescription)
        }
    }

    func joinLeague(code: String) async throws -> JoinLeagueResponse {
        do {
            Log.leagues.info("Joining league with code")
            let response: JoinLeagueResponse = try await client.functions.invoke(
                "join-league",
                options: FunctionInvokeOptions(body: ["code": code])
            )
            Log.leagues.info("Joined league: \(response.leagueId)")
            return response
        } catch {
            Log.leagues.error("Join league failed: \(error)")
            throw LeagueServiceError.joinFailed(error.localizedDescription)
        }
    }

    func fetchMyLeagues() async throws -> [League] {
        do {
            let userId = try await client.auth.session.user.id.uuidString

            // Single query: join through league_members → leagues with member count
            let rows: [MemberWithLeagueRow] = try await client
                .from("league_members")
                .select(
                    """
                    leagues(id, name, join_code, type, status, season, \
                    created_at, league_members(count))
                    """
                )
                .eq("user_id", value: userId)
                .execute()
                .value

            return rows
                .map { $0.leagues.toLeague() }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            throw LeagueServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchOpenLeagues() async throws -> [BrowseLeague] {
        do {
            let userId = try await client.auth.session.user.id.uuidString

            let myRows: [LeagueMemberRow] = try await client
                .from("league_members")
                .select(
                    """
                    league_id, \
                    leagues(id, name, join_code, type, status, season, created_at)
                    """
                )
                .eq("user_id", value: userId)
                .execute()
                .value
            let myLeagueIds = Set(myRows.map(\.leagueId))

            let allOpen: [BrowseLeagueRow] = try await client
                .from("leagues")
                .select(
                    """
                    id, name, join_code, status, season, created_at, \
                    league_members(count)
                    """
                )
                .eq("type", value: "free")
                .in("status", values: ["pending", "active"])
                .order("created_at", ascending: false)
                .execute()
                .value

            return allOpen
                .filter { !myLeagueIds.contains($0.id) }
                .map { $0.toBrowseLeague() }
        } catch {
            throw LeagueServiceError.fetchFailed(error.localizedDescription)
        }
    }
}
