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
}

// MARK: - Mock

final class MockAuthService: AuthServiceProtocol {
    var signInCalled = false
    var signUpCalled = false
    var shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
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
}
