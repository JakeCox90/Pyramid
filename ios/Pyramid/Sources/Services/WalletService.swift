import Foundation
import os
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
            Log.wallet.info("Fetching wallet balance")
            let balance: WalletBalance = try await client.functions.invoke(
                "get-wallet",
                options: FunctionInvokeOptions()
            )
            Log.wallet.info("Wallet balance fetched")
            return balance
        } catch {
            Log.wallet.error("Wallet fetch failed: \(error.localizedDescription)")
            CrashReporter.capture(error, context: ["service": "wallet", "op": "fetch"])
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
            Log.wallet.info("Requesting withdrawal: \(amountPence)p")
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
            Log.wallet.info("Withdrawal request succeeded: \(amountPence)p")
        } catch {
            Log.wallet.error("Withdrawal failed: \(error.localizedDescription)")
            CrashReporter.capture(error, context: [
                "service": "wallet", "op": "withdrawal",
                "amount_pence": "\(amountPence)"
            ])
            throw WalletServiceError.withdrawalFailed(error.localizedDescription)
        }
    }

    // Stripe PaymentSheet integration pending GATE decision
    // This stub will be replaced with real Stripe confirmation flow once GATE is approved.
    func topUp(amountPence: Int, paymentIntentId: String) async throws {
        Log.wallet.info("Top-up initiated: \(amountPence)p")
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
            Log.wallet.info("Top-up succeeded: \(amountPence)p")
        } catch {
            Log.wallet.error("Top-up failed: \(error.localizedDescription)")
            CrashReporter.capture(error, context: [
                "service": "wallet", "op": "top_up",
                "amount_pence": "\(amountPence)"
            ])
            throw WalletServiceError.topUpFailed(error.localizedDescription)
        }
    }
}
