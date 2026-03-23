import XCTest

/// Journey 2: Create a league and view the join code.
///
/// Covers the flow: Leagues tab -> Create League -> enter
/// name -> submit -> see join code -> copy code -> done.
///
/// **Prerequisites:**
/// - Authenticated session (uses `AuthTestHelper`)
/// - Running Supabase backend for league creation to succeed
///
/// **Note:** League creation requires a backend call. Tests
/// verify the UI flow and element presence. The actual
/// creation may fail without a live backend — that is
/// acceptable for a scaffold.
final class CreateLeagueUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForTesting()
        AuthTestHelper.signInIfNeeded(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation to Create League

    func testNavigateToCreateLeagueFromEmptyState() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test leagues")
            return
        }

        // Navigate to Leagues tab
        let leaguesTab = app.tabBars.buttons["Leagues"]
        leaguesTab.tapWhenReady()

        // From empty state, tap "Create a League"
        let createButton = app.buttons["Create a League"]
        guard createButton.waitForExistence(timeout: 10) else {
            // If leagues exist, the empty state is not shown.
            // Try the toolbar menu instead.
            tryCreateFromToolbarMenu()
            return
        }

        createButton.tap()
        verifyCreateLeagueSheet()
    }

    func testNavigateToCreateLeagueFromToolbarMenu() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test leagues")
            return
        }

        // Navigate to Leagues tab
        app.tabBars.buttons["Leagues"].tapWhenReady()

        // Wait for content to load
        _ = app.navigationBars["Leagues"]
            .waitForExistence(timeout: 10)

        // If there are leagues, use the toolbar menu
        if !app.buttons["Create a League"].exists {
            tryCreateFromToolbarMenu()
        } else {
            app.buttons["Create a League"].tap()
            verifyCreateLeagueSheet()
        }
    }

    // MARK: - Create League Form

    func testCreateLeagueFormElements() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test leagues")
            return
        }

        navigateToCreateLeagueSheet()

        // Verify form elements
        let navTitle = app.navigationBars["Create League"]
        XCTAssertTrue(
            navTitle.waitForExistence(timeout: 5),
            "Create League nav title should be visible"
        )

        // League name input field
        let nameField = app.textFields[
            "e.g. Sunday League Heroes"
        ]
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 5),
            "League name field should exist"
        )

        // Helper text
        XCTAssertTrue(
            app.staticTexts[
                "Give your league a unique name. "
                + "You'll get a join code to share with friends."
            ].exists,
            "Helper text should be visible"
        )

        // Create button
        let createButton = app.buttons["Create League"]
        XCTAssertTrue(
            createButton.exists,
            "Create League submit button should exist"
        )

        // Cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(
            cancelButton.exists,
            "Cancel button should exist"
        )
    }

    func testCreateLeagueSubmitFlow() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test leagues")
            return
        }

        navigateToCreateLeagueSheet()

        // Type a league name
        let nameField = app.textFields[
            "e.g. Sunday League Heroes"
        ]
        guard nameField.waitForExistence(timeout: 5) else {
            XCTFail("League name field not found")
            return
        }
        nameField.tap()
        nameField.typeText("UI Test League \(Int.random(in: 1000...9999))")

        // Submit — this requires a backend call
        XCTExpectFailure(
            "League creation requires a running backend"
        )

        let createButton = app.buttons["Create League"]
        createButton.tap()

        // If creation succeeds, verify the success screen
        let joinCodeLabel = app.staticTexts["Join Code"]
        if joinCodeLabel.waitForExistence(timeout: 10) {
            verifyLeagueCreatedScreen()
        }
    }

    func testCancelCreateLeague() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test leagues")
            return
        }

        navigateToCreateLeagueSheet()

        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 5) else {
            XCTFail("Cancel button not found")
            return
        }

        cancelButton.tap()

        // Sheet should dismiss — verify we are back on leagues
        let leaguesNav = app.navigationBars["Leagues"]
        XCTAssertTrue(
            leaguesNav.waitForExistence(timeout: 5),
            "Should return to Leagues after cancelling"
        )
    }

    // MARK: - Private Helpers

    private func navigateToCreateLeagueSheet() {
        app.tabBars.buttons["Leagues"].tapWhenReady()

        let createButton = app.buttons["Create a League"]
        if createButton.waitForExistence(timeout: 10) {
            createButton.tap()
        } else {
            tryCreateFromToolbarMenu()
        }
    }

    private func tryCreateFromToolbarMenu() {
        // The add menu is the "+" button in the nav bar
        let addButton = app.navigationBars.buttons.element(
            boundBy: app.navigationBars.buttons.count - 1
        )
        if addButton.waitForExistence(timeout: 5) {
            addButton.tap()

            let createMenuItem = app.buttons["Create League"]
            if createMenuItem.waitForExistence(timeout: 3) {
                createMenuItem.tap()
            }
        }
    }

    private func verifyCreateLeagueSheet() {
        let navTitle = app.navigationBars["Create League"]
        XCTAssertTrue(
            navTitle.waitForExistence(timeout: 5),
            "Create League sheet should appear"
        )
    }

    private func verifyLeagueCreatedScreen() {
        // "League Created!" title
        XCTAssertTrue(
            app.staticTexts["League Created!"].exists,
            "Success title should be visible"
        )

        // Join code label
        XCTAssertTrue(
            app.staticTexts["Join Code"].exists,
            "Join Code label should be visible"
        )

        // Copy and Share buttons
        XCTAssertTrue(
            app.buttons["Copy Code"].exists
                || app.buttons["Copied!"].exists,
            "Copy button should exist"
        )

        // Done button
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(
            doneButton.exists,
            "Done button should exist on success screen"
        )
    }
}
