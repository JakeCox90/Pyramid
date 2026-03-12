import XCTest
@testable import Pyramid

@MainActor
final class ProfileViewModelTests: XCTestCase {

    // MARK: - signOut

    func testSignOutSuccessReturnsTrue() async {
        let mock = MockProfileAuthService()
        let vm = ProfileViewModel(authService: mock)

        let result = await vm.signOut()

        XCTAssertTrue(result)
        XCTAssertFalse(vm.isSigningOut)
        XCTAssertNil(vm.errorMessage)
    }

    func testSignOutFailureSetsErrorMessage() async {
        let mock = MockProfileAuthService(shouldFail: true)
        let vm = ProfileViewModel(authService: mock)

        let result = await vm.signOut()

        XCTAssertFalse(result)
        XCTAssertFalse(vm.isSigningOut)
        XCTAssertNotNil(vm.errorMessage)
    }
}

// MARK: - Mock

private final class MockProfileAuthService: AuthServiceProtocol {
    var shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String) async throws {}

    func signOut() async throws {
        if shouldFail { throw URLError(.badServerResponse) }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {}
    func signInWithGoogle() async throws {}
}
