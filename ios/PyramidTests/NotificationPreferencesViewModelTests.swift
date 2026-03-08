import XCTest
@testable import Pyramid

@MainActor
final class NotificationPreferencesViewModelTests: XCTestCase {

    // MARK: - load()

    func testLoadFetchesPreferencesFromService() async {
        let mock = MockNotificationPreferencesService()
        mock.stubbedPreferences = NotificationPreferences(
            deadlineReminders: true,
            pickLocked: false,
            resultAlerts: true,
            winningsAlerts: false
        )
        let vm = NotificationPreferencesViewModel(service: mock)

        await vm.load()

        XCTAssertTrue(mock.fetchCalled)
        XCTAssertTrue(vm.preferences.deadlineReminders)
        XCTAssertFalse(vm.preferences.pickLocked)
        XCTAssertTrue(vm.preferences.resultAlerts)
        XCTAssertFalse(vm.preferences.winningsAlerts)
    }

    func testLoadSetsIsLoadingFalseAfterSuccess() async {
        let mock = MockNotificationPreferencesService()
        let vm = NotificationPreferencesViewModel(service: mock)

        await vm.load()

        XCTAssertFalse(vm.isLoading)
    }

    func testLoadSetsErrorMessageOnFailure() async {
        let mock = MockNotificationPreferencesService(shouldFail: true)
        let vm = NotificationPreferencesViewModel(service: mock)

        await vm.load()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoadClearsErrorMessageOnSuccess() async {
        let mock = MockNotificationPreferencesService()
        let vm = NotificationPreferencesViewModel(service: mock)
        vm.errorMessage = "previous error"

        await vm.load()

        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - save()

    func testSaveCallsServiceWithUpdatedPreferences() async {
        let mock = MockNotificationPreferencesService()
        let vm = NotificationPreferencesViewModel(service: mock)
        await vm.load()

        vm.preferences.deadlineReminders = false
        await vm.save()

        XCTAssertTrue(mock.updateCalled)
        XCTAssertEqual(mock.lastUpdatedPreferences?.deadlineReminders, false)
    }

    func testSaveServiceErrorSetsErrorMessage() async {
        let mock = MockNotificationPreferencesService(updateShouldFail: true)
        let vm = NotificationPreferencesViewModel(service: mock)
        await vm.load()

        await vm.save()

        XCTAssertNotNil(vm.errorMessage)
    }
}

// MARK: - Mock

final class MockNotificationPreferencesService: NotificationPreferencesServiceProtocol, @unchecked Sendable {
    var stubbedPreferences = NotificationPreferences.defaultPreferences
    var shouldFail: Bool
    var updateShouldFail: Bool

    private(set) var fetchCalled = false
    private(set) var updateCalled = false
    private(set) var lastUpdatedPreferences: NotificationPreferences?

    init(shouldFail: Bool = false, updateShouldFail: Bool = false) {
        self.shouldFail = shouldFail
        self.updateShouldFail = updateShouldFail
    }

    func fetchPreferences() async throws -> NotificationPreferences {
        fetchCalled = true
        if shouldFail { throw URLError(.badServerResponse) }
        return stubbedPreferences
    }

    func updatePreferences(_ prefs: NotificationPreferences) async throws {
        updateCalled = true
        lastUpdatedPreferences = prefs
        if updateShouldFail { throw URLError(.badServerResponse) }
    }
}
