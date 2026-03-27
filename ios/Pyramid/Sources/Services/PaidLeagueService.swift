import Foundation
import os
import Supabase

// MARK: - Errors

enum PaidLeagueServiceError: LocalizedError, Equatable {
    case insufficientBalance
    case leagueCapReached
    case joinFailed(String)

    var errorDescription: String? {
        switch self {
        case .insufficientBalance:
            return "You don't have enough balance to join. Please top up your wallet."
        case .leagueCapReached:
            return "This league is full. No more players can join."
        case .joinFailed(let message):
            return message
        }
    }
}

// MARK: - Protocol

protocol PaidLeagueServiceProtocol: Sendable {
    func joinPaidLeague() async throws -> JoinPaidLeagueResponse
    func fetchWalletBalance() async throws -> Int
}

// MARK: - Implementation

final class PaidLeagueService: PaidLeagueServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func joinPaidLeague() async throws -> JoinPaidLeagueResponse {
        Log.leagues.info("Joining paid league")
        do {
            let response: JoinPaidLeagueResponse = try await client.functions.invoke(
                "join-paid-league",
                options: FunctionInvokeOptions(body: EmptyBody())
            )
            Log.leagues.info("Joined paid league: \(response.leagueId)")
            return response
        } catch let error as FunctionsError {
            switch error {
            case .httpError(let code, let data):
                if code == 402 {
                    throw PaidLeagueServiceError.insufficientBalance
                }
                if code == 409,
                   let body = String(data: data, encoding: .utf8),
                   body.contains("LEAGUE_CAP_REACHED") {
                    throw PaidLeagueServiceError.leagueCapReached
                }
                CrashReporter.capture(error, context: [
                    "service": "paid_league", "op": "join",
                    "http_code": "\(code)"
                ])
                throw PaidLeagueServiceError.joinFailed(error.localizedDescription)
            default:
                CrashReporter.capture(error, context: [
                    "service": "paid_league", "op": "join"
                ])
                throw PaidLeagueServiceError.joinFailed(error.localizedDescription)
            }
        } catch {
            CrashReporter.capture(error, context: [
                "service": "paid_league", "op": "join"
            ])
            throw PaidLeagueServiceError.joinFailed(error.localizedDescription)
        }
    }

    func fetchWalletBalance() async throws -> Int {
        struct WalletResponse: Decodable {
            let balancePence: Int
            enum CodingKeys: String, CodingKey {
                case balancePence = "balance_pence"
            }
        }
        do {
            let response: WalletResponse = try await client.functions.invoke(
                "get-wallet",
                options: FunctionInvokeOptions(method: .get)
            )
            return response.balancePence
        } catch {
            throw PaidLeagueServiceError.joinFailed(error.localizedDescription)
        }
    }
}

// MARK: - EmptyBody

private struct EmptyBody: Encodable {}
