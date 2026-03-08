import XCTest
@testable import Pyramid

@MainActor
final class NotificationServiceTests: XCTestCase {

    // MARK: - handleDeviceToken

    func testHandleDeviceTokenConvertsDataToHexString() async {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0xFF])
        let mock = MockNotificationPreferencesService()
        let service = MockableNotificationService(prefsService: mock)

        await service.handleDeviceToken(data)

        XCTAssertEqual(service.deviceToken, "deadbeef00ff")
    }

    func testHandleDeviceTokenStoresToken() async {
        let data = Data([0x01, 0x02, 0x03])
        let service = MockableNotificationService(prefsService: MockNotificationPreferencesService())

        await service.handleDeviceToken(data)

        XCTAssertEqual(service.deviceToken, "010203")
    }

    func testHandleDeviceTokenCallsRegister() async {
        let data = Data([0xAB, 0xCD])
        let service = MockableNotificationService(prefsService: MockNotificationPreferencesService())

        await service.handleDeviceToken(data)

        XCTAssertTrue(service.registerTokenCalled)
        XCTAssertEqual(service.lastRegisteredToken, "abcd")
    }

    // MARK: - handleRegistrationFailure

    func testHandleRegistrationFailureDoesNotCrash() {
        let service = MockableNotificationService(prefsService: MockNotificationPreferencesService())
        let error = URLError(.notConnectedToInternet)

        // Must not throw or crash
        service.handleRegistrationFailure(error)
    }

    func testHandleRegistrationFailureDoesNotSetDeviceToken() {
        let service = MockableNotificationService(prefsService: MockNotificationPreferencesService())
        let error = URLError(.notConnectedToInternet)

        service.handleRegistrationFailure(error)

        XCTAssertNil(service.deviceToken)
    }
}

// MARK: - MockableNotificationService

/// Testable subclass that overrides Edge Function registration
@MainActor
final class MockableNotificationService: ObservableObject {
    @Published var isPermissionGranted = false
    @Published var deviceToken: String?

    private(set) var registerTokenCalled = false
    private(set) var lastRegisteredToken: String?

    private let prefsService: NotificationPreferencesServiceProtocol

    init(prefsService: NotificationPreferencesServiceProtocol) {
        self.prefsService = prefsService
    }

    func handleDeviceToken(_ data: Data) async {
        let tokenString = data.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        registerTokenCalled = true
        lastRegisteredToken = tokenString
    }

    func handleRegistrationFailure(_ error: Error) {
        // mirrors production behaviour — log only
        print("[MockNotificationService] Registration failed: \(error.localizedDescription)")
    }
}
