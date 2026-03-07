import Foundation
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

// MARK: - Protocol

protocol LeagueServiceProtocol: Sendable {
    func createLeague(name: String) async throws -> CreateLeagueResponse
    func previewLeague(code: String) async throws -> LeaguePreview
    func joinLeague(code: String) async throws -> JoinLeagueResponse
    func fetchMyLeagues() async throws -> [League]
}

// MARK: - Implementation

final class LeagueService: LeagueServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func createLeague(name: String) async throws -> CreateLeagueResponse {
        do {
            let response: CreateLeagueResponse = try await client.functions.invoke(
                "create-league",
                options: FunctionInvokeOptions(body: ["name": name])
            )
            return response
        } catch {
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
            let response: JoinLeagueResponse = try await client.functions.invoke(
                "join-league",
                options: FunctionInvokeOptions(body: ["code": code])
            )
            return response
        } catch {
            throw LeagueServiceError.joinFailed(error.localizedDescription)
        }
    }

    func fetchMyLeagues() async throws -> [League] {
        do {
            let leagues: [League] = try await client
                .from("leagues")
                .select("id, name, join_code, type, status, season, created_at")
                .order("created_at", ascending: false)
                .execute()
                .value
            return leagues
        } catch {
            throw LeagueServiceError.fetchFailed(error.localizedDescription)
        }
    }
}
