import XCTest
@testable import Pyramid

@MainActor
final class AuthViewModelTests: XCTestCase {
    func testSignInWithEmptyFieldsShowsError() async {
        let vm = AuthViewModel(authService: MockAuthService())
        vm.email = ""
        vm.password = ""

        await vm.signIn()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testSignInSuccessCallsService() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)
        vm.email = "test@example.com"
        vm.password = "password123"

        await vm.signIn()

        XCTAssertTrue(mock.signInCalled)
        XCTAssertNil(vm.errorMessage)
    }

    func testSignInFailureSetsErrorMessage() async {
        let mock = MockAuthService(shouldFail: true)
        let vm = AuthViewModel(authService: mock)
        vm.email = "test@example.com"
        vm.password = "wrong"

        await vm.signIn()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Google Sign-In

    func testGoogleSignInSuccessClearsError() async {
        let mock = MockAuthService()
        let vm = AuthViewModel(authService: mock)

        await vm.signInWithGoogle()

        XCTAssertTrue(mock.googleSignInCalled)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isSocialLoading)
    }

    func testGoogleSignInFailureSetsErrorMessage() async {
        let mock = MockAuthService(shouldFail: true)
        let vm = AuthViewModel(authService: mock)

        await vm.signInWithGoogle()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isSocialLoading)
    }

    func testGoogleSignInCancellationShowsNoError() async {
        let mock = MockAuthService(cancelGoogle: true)
        let vm = AuthViewModel(authService: mock)

        await vm.signInWithGoogle()

        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isSocialLoading)
    }
}

// MARK: - Mock

final class MockAuthService: AuthServiceProtocol {
    var signInCalled = false
    var signUpCalled = false
    var googleSignInCalled = false
    var shouldFail: Bool
    var cancelGoogle: Bool

    init(shouldFail: Bool = false, cancelGoogle: Bool = false) {
        self.shouldFail = shouldFail
        self.cancelGoogle = cancelGoogle
    }

    func signIn(email: String, password: String) async throws {
        signInCalled = true
        if shouldFail { throw URLError(.badServerResponse) }
    }

    func signUp(email: String, password: String) async throws {
        signUpCalled = true
        if shouldFail { throw URLError(.badServerResponse) }
    }

    func signOut() async throws {}

    func signInWithApple(idToken: String, nonce: String) async throws {
        if shouldFail { throw URLError(.badServerResponse) }
    }

    func signInWithGoogle() async throws {
        googleSignInCalled = true
        if cancelGoogle {
            throw NSError(
                domain: "com.apple.AuthenticationServices.WebAuthenticationSession",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The operation couldn't be completed."]
            )
        }
        if shouldFail { throw URLError(.badServerResponse) }
    }
}
