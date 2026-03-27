import XCTest
@testable import Pyramid

final class CrashReporterTests: XCTestCase {

    // MARK: - start() without DSN

    func testStartWithoutDSN_doesNotCrash() {
        // CrashReporter.start() should silently no-op when SENTRY_DSN is empty.
        // In unit tests the Info.plist key is empty, so this validates the guard.
        CrashReporter.start()
    }

    // MARK: - capture without init

    func testCaptureBeforeStart_doesNotCrash() {
        // Calling capture before Sentry is initialised should be a safe no-op.
        let error = NSError(domain: "test", code: 42)
        CrashReporter.capture(error, context: ["test": "value"])
    }

    func testCaptureMessageBeforeStart_doesNotCrash() {
        CrashReporter.captureMessage("test message", context: ["key": "val"])
    }

    // MARK: - User context without init

    func testSetUserBeforeStart_doesNotCrash() {
        CrashReporter.setUser(id: "user-123")
    }

    func testClearUserBeforeStart_doesNotCrash() {
        CrashReporter.clearUser()
    }

    // MARK: - Breadcrumb without init

    func testAddBreadcrumbBeforeStart_doesNotCrash() {
        CrashReporter.addBreadcrumb(
            category: "navigation",
            message: "Opened league detail",
            data: ["league_id": "abc"]
        )
    }
}
