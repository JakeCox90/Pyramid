import Foundation
import Supabase

// MARK: - Response

struct ModerationResult: Decodable, Sendable {
    let valid: Bool
    let field: String?
    let reason: String?
}

// MARK: - Error

enum ContentModerationError: LocalizedError, Equatable {
    case validationFailed(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let reason):
            return reason
        case .requestFailed(let message):
            return message
        }
    }
}

// MARK: - Protocol

protocol ContentModerationServiceProtocol: Sendable {
    func validate(
        name: String?,
        description: String?
    ) async throws -> ModerationResult
}

// MARK: - Implementation

final class ContentModerationService:
    ContentModerationServiceProtocol {

    private let client: SupabaseClient

    init(
        client: SupabaseClient =
            SupabaseDependency.shared.client
    ) {
        self.client = client
    }

    func validate(
        name: String?,
        description: String?
    ) async throws -> ModerationResult {
        do {
            var body: [String: String] = [:]
            if let name { body["name"] = name }
            if let description {
                body["description"] = description
            }

            let result: ModerationResult =
                try await client.functions.invoke(
                    "validate-league-content",
                    options: FunctionInvokeOptions(
                        body: body
                    )
                )
            return result
        } catch {
            throw ContentModerationError.requestFailed(
                error.localizedDescription
            )
        }
    }
}
