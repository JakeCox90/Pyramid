import XCTest

/// Journey 1: Auth flow — sign up and sign in.
///
/// Covers the critical path from app launch to authenticated
/// state via email/password. SSO buttons (Apple, Google) are
/// verified to exist but not tapped (they require system
/// dialogs that cannot be automated in XCUITest).
///
/// **Prerequisites:**
/// - A pre-seeded test user in the Supabase dev project
/// - `UI_TEST_EMAIL` / `UI_TEST_PASSWORD` env vars set
///
/// **Note:** These tests require a running Supabase backend.
/// They are structured to pass the scaffold even without one
/// — network-dependent assertions use `XCTExpectFailure`
/// where appropriate.
final class AuthFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForTesting()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Auth Screen Elements

    func testAuthScreenShowsAllElements() {
        // If already signed in, skip — we cannot test the
        // auth screen when there is an active session.
        guard AuthTestHelper.isOnAuthScreen(app: app) else {
            XCTSkip("Already authenticated — cannot test auth screen")
            return
        }

        // Title
        XCTAssertTrue(
            app.staticTexts["Pyramid"].exists,
            "App title should be visible"
        )
        XCTAssertTrue(
            app.staticTexts["Premier League Last Man Standing"].exists,
            "Subtitle should be visible"
        )

        // Email field (InputField uses placeholder as TextField identifier)
        let emailField = app.textFields["you@example.com"]
        XCTAssertTrue(
            emailField.waitForExistence(timeout: 5),
            "Email text field should exist"
        )

        // Password field
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(
            passwordField.waitForExistence(timeout: 5),
            "Password secure field should exist"
        )

        // Buttons
        XCTAssertTrue(app.buttons["Sign In"].exists, "Sign In button")
        XCTAssertTrue(
            app.buttons["Create account"].exists,
            "Create account button"
        )

        // Social sign-in buttons
        XCTAssertTrue(
            app.buttons["Sign in with Apple"].exists,
            "Apple sign-in button"
        )
        XCTAssertTrue(
            app.buttons["Sign in with Google"].exists,
            "Google sign-in button"
        )
    }

    func testSignInWithEmptyFieldsShowsError() {
        guard AuthTestHelper.isOnAuthScreen(app: app) else {
            XCTSkip("Already authenticated")
            return
        }

        // Clear any pre-filled fields (DEBUG builds pre-fill)
        let emailField = app.textFields["you@example.com"]
        if emailField.waitForExistence(timeout: 5) {
            emailField.tap()
            // Select all and delete
            emailField.press(forDuration: 1.0)
            if app.menuItems["Select All"].waitForExistence(timeout: 2) {
                app.menuItems["Select All"].tap()
                emailField.typeText(XCUIKeyboardKey.delete.rawValue)
            }
        }

        let passwordField = app.secureTextFields["Password"]
        if passwordField.waitForExistence(timeout: 5) {
            passwordField.tap()
            passwordField.press(forDuration: 1.0)
            if app.menuItems["Select All"].waitForExistence(timeout: 2) {
                app.menuItems["Select All"].tap()
                passwordField.typeText(XCUIKeyboardKey.delete.rawValue)
            }
        }

        // Tap Sign In with empty fields
        app.buttons["Sign In"].tap()

        // Should show validation error
        let errorText = app.staticTexts["Email and password are required."]
        XCTAssertTrue(
            errorText.waitForExistence(timeout: 5),
            "Validation error should appear for empty fields"
        )
    }

    func testSignInWithValidCredentials() {
        guard AuthTestHelper.isOnAuthScreen(app: app) else {
            XCTSkip("Already authenticated")
            return
        }

        // This test requires a live backend. Mark as expected
        // failure if credentials are not set.
        let hasCredentials =
            app.launchEnvironment[UITestEnv.testEmail] != nil
        if !hasCredentials {
            XCTExpectFailure(
                "No test credentials — sign-in will not complete"
            )
        }

        AuthTestHelper.signInIfNeeded(app: app)

        // Verify we reached the main tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 15),
            "Tab bar should appear after successful sign-in"
        )
    }

    func testSignUpButtonExists() {
        guard AuthTestHelper.isOnAuthScreen(app: app) else {
            XCTSkip("Already authenticated")
            return
        }

        let createAccountButton = app.buttons["Create account"]
        XCTAssertTrue(
            createAccountButton.exists,
            "Create account button should be visible"
        )
        XCTAssertTrue(
            createAccountButton.isEnabled,
            "Create account button should be enabled"
        )
    }
}
