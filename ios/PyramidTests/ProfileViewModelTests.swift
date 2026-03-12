import XCTest
@testable import Pyramid

@MainActor
final class ProfileViewModelTests: XCTestCase {

    // MARK: - signOut

    func testSignOutSuccessReturnsTrue() async {
        let mock = MockAuthService()
        let vm = ProfileViewModel(authService: mock)

        let result = await vm.signOut()

        XCTAssertTrue(result)
        XCTAssertFalse(vm.isSigningOut)
        XCTAssertNil(vm.errorMessage)
    }

    func testSignOutFailureSetsErrorMessage() async {
        let mock = MockAuthService(shouldFailSignOut: true)
        let vm = ProfileViewModel(authService: mock)

        let result = await vm.signOut()

        XCTAssertFalse(result)
        XCTAssertFalse(vm.isSigningOut)
        XCTAssertNotNil(vm.errorMessage)
    }
}

// MARK: - Mock

private final class MockAuthService: AuthServiceProtocol {
    var shouldFailSignOut: Bool

    init(shouldFailSignOut: Bool = false) {
        self.shouldFailSignOut = shouldFailSignOut
    }

    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String) async throws {}

    func signOut() async throws {
        if shouldFailSignOut {
            throw URLError(.badServerResponse)
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {}
    func signInWithGoogle() async throws {}
}
