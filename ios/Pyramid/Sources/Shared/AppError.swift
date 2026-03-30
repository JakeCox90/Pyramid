import Foundation

// MARK: - AppError

/// Typed error enum that maps raw errors to user-friendly messages.
/// Use `AppError.from(_:)` to convert any thrown `Error` into a categorised `AppError`.
enum AppError: LocalizedError {
    case network(underlying: Error)
    case auth(underlying: Error)
    case server(underlying: Error)
    case rateLimited(retryAfter: Int?)
    case domain(message: String, underlying: Error)
    case unknown(underlying: Error)

    // MARK: User-facing message

    var userMessage: String {
        switch self {
        case .network:
            return "Check your internet connection and try again."
        case .auth:
            return "Your session has expired. Please sign in again."
        case .server:
            return "Something went wrong on our end. Please try again later."
        case .rateLimited:
            return "You're doing that too fast. Please wait a moment and try again."
        case .domain(let message, _):
            return message
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    // MARK: LocalizedError

    var errorDescription: String? { userMessage }

    // MARK: Factory

    /// Inspects `error` and returns the most appropriate `AppError` category.
    static func from(_ error: Error) -> AppError {
        // Rate limiting (HTTP 429)
        let description429 = error.localizedDescription.lowercased()
        if description429.contains("429") || description429.contains("rate_limited") || description429.contains("too many requests") {
            return .rateLimited(retryAfter: nil)
        }

        // Network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost:
                return .network(underlying: error)
            default:
                break
            }
        }

        let description = error.localizedDescription.lowercased()

        // Network keywords
        let networkKeywords = ["not connected to the internet", "network connection lost", "timed out"]
        if networkKeywords.contains(where: { description.contains($0) }) {
            return .network(underlying: error)
        }

        // Auth / session keywords
        let authKeywords = ["jwt", "session", "auth", "token expired", "refresh_token"]
        if authKeywords.contains(where: { description.contains($0) }) {
            return .auth(underlying: error)
        }

        // Server error keywords
        let serverKeywords = ["500", "502", "503", "internal server error"]
        if serverKeywords.contains(where: { description.contains($0) }) {
            return .server(underlying: error)
        }

        // Domain-specific errors that already provide user-facing messages
        if let localizedError = error as? LocalizedError,
           let message = localizedError.errorDescription {
            return .domain(message: message, underlying: error)
        }

        return .unknown(underlying: error)
    }
}
