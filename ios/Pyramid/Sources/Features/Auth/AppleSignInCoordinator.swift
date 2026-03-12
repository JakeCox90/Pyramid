import AuthenticationServices
import CryptoKit
import Foundation

/// Handles the native Apple Sign-In flow and returns credentials to the caller.
/// Generates a SHA256 nonce, presents ASAuthorizationController, and resolves
/// with (idToken, nonce) on success or throws on failure/cancellation.
@MainActor
final class AppleSignInCoordinator: NSObject {

    private var continuation: CheckedContinuation<(idToken: String, nonce: String), Error>?
    private var rawNonce: String = ""

    func signIn() async throws -> (idToken: String, nonce: String) {
        rawNonce = Self.randomNonce()
        let hashedNonce = Self.sha256(rawNonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Nonce Helpers

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce — SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                continuation?.resume(throwing: AppleSignInError.invalidCredential)
                continuation = nil
                return
            }
            continuation?.resume(returning: (idToken: idToken, nonce: rawNonce))
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            let appleError = error as? ASAuthorizationError
            if appleError?.code == .canceled {
                continuation?.resume(throwing: AppleSignInError.cancelled)
            } else {
                continuation?.resume(throwing: error)
            }
            continuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // ASAuthorizationControllerPresentationContextProviding requires nonisolated,
        // but UIApplication access must be on MainActor. We dispatch synchronously
        // since this delegate method is always called on the main thread at runtime.
        var window: UIWindow?
        if Thread.isMainThread {
            window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return window ?? UIWindow()
    }
}

// MARK: - Errors

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Apple Sign-In failed. Please try again."
        case .cancelled:
            return nil
        }
    }
}
