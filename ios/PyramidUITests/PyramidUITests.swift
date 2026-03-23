import XCTest

/// Smoke test that verifies the app launches without crashing.
/// This runs as part of the UI test suite and is the most basic
/// health check.
final class PyramidUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForTesting()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunchesSuccessfully() {
        // The app should show either:
        // - Auth screen (not signed in)
        // - Onboarding (first launch after sign in)
        // - Main tab view (signed in)
        // Any of these indicates a successful launch.
        let authTitle = app.staticTexts["Pyramid"]
        let tabBar = app.tabBars.firstMatch

        let launched = authTitle.waitForExistence(timeout: 15)
            || tabBar.waitForExistence(timeout: 15)

        XCTAssertTrue(
            launched,
            "App should launch and show auth or main screen"
        )
    }
}
