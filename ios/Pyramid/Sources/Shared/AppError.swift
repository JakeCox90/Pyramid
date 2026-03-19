import Foundation

// MARK: - AppError

/// Typed error enum that maps raw errors to user-friendly messages.
/// Use `AppError.from(_:)` to convert any thrown `Error` into a categorised `AppError`.
enum AppError: LocalizedError {
    case network(underlying: Error)
    case auth(underlying: Error)
    case server(underlying: Error)
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
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    // MARK: LocalizedError

    var errorDescription: String? { userMessage }

    // MARK: Factory

    /// Inspects `error` and returns the most appropriate `AppError` category.
    static func from(_ error: Error) -> AppError {
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

        return .unknown(underlying: error)
    }
}
