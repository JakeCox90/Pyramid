import Foundation
import Supabase

// MARK: - Error

enum WalletServiceError: LocalizedError {
    case fetchFailed(String)
    case withdrawalFailed(String)
    case topUpFailed(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return message
        case .withdrawalFailed(let message):
            return message
        case .topUpFailed(let message):
            return message
        }
    }
}

// MARK: - Protocol

protocol WalletServiceProtocol: Sendable {
    func fetchWallet() async throws -> WalletBalance
    func fetchTransactions() async throws -> [WalletTransaction]
    func requestWithdrawal(amountPence: Int) async throws
    func topUp(amountPence: Int, paymentIntentId: String) async throws
}

// MARK: - Implementation

final class WalletService: WalletServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchWallet() async throws -> WalletBalance {
        do {
            let balance: WalletBalance = try await client.functions.invoke(
                "get-wallet",
                options: FunctionInvokeOptions()
            )
            return balance
        } catch {
            throw WalletServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func fetchTransactions() async throws -> [WalletTransaction] {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let transactions: [WalletTransaction] = try await client
                .from("wallet_transactions")
                .select("id, type, amount_pence, created_at, notes, dispute_window_expires_at")
                .order("created_at", ascending: false)
                .execute()
                .value
            return transactions
        } catch {
            throw WalletServiceError.fetchFailed(error.localizedDescription)
        }
    }

    func requestWithdrawal(amountPence: Int) async throws {
        do {
            struct WithdrawalRequest: Encodable {
                let amountPence: Int
                enum CodingKeys: String, CodingKey {
                    case amountPence = "amount_pence"
                }
            }
            let _: Data = try await client.functions.invoke(
                "request-withdrawal",
                options: FunctionInvokeOptions(body: WithdrawalRequest(amountPence: amountPence))
            )
        } catch {
            throw WalletServiceError.withdrawalFailed(error.localizedDescription)
        }
    }

    // TODO: PYR-25 GATE — Stripe PaymentSheet integration is pending.
    // This stub will be replaced with real Stripe confirmation flow once PYR-25 is approved.
    func topUp(amountPence: Int, paymentIntentId: String) async throws {
        do {
            struct TopUpRequest: Encodable {
                let amountPence: Int
                let paymentIntentId: String
                enum CodingKeys: String, CodingKey {
                    case amountPence = "amount_pence"
                    case paymentIntentId = "payment_intent_id"
                }
            }
            let _: Data = try await client.functions.invoke(
                "top-up",
                options: FunctionInvokeOptions(body: TopUpRequest(
                    amountPence: amountPence,
                    paymentIntentId: paymentIntentId
                ))
            )
        } catch {
            throw WalletServiceError.topUpFailed(error.localizedDescription)
        }
    }
}
