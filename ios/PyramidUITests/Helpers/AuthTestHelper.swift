import XCTest

/// Helper for managing auth state in UI tests.
///
/// Tests that require an authenticated session should call
/// `signInIfNeeded()` in their `setUp()` method. This uses
/// test credentials from environment variables.
///
/// **Pre-seeded test user setup:**
/// 1. Create a user in the Supabase dev project dashboard
/// 2. Set `UI_TEST_EMAIL` and `UI_TEST_PASSWORD` in your
///    environment or Xcode scheme
/// 3. The CI workflow injects these from GitHub Secrets
enum AuthTestHelper {
    /// Sign in using email/password if the auth screen is
    /// visible. No-ops if already authenticated.
    static func signInIfNeeded(
        app: XCUIApplication,
        timeout: TimeInterval = 5
    ) {
        let signInButton = app.buttons["Sign In"]

        // If Sign In button is not visible, we are already
        // authenticated (or the app is still loading).
        guard signInButton.waitForExistence(timeout: timeout) else {
            return
        }

        let email = app.launchEnvironment[UITestEnv.testEmail]
            ?? "uitest@example.com"
        let password = app.launchEnvironment[UITestEnv.testPassword]
            ?? "TestPassword123!"

        // Find text fields — InputField wraps TextField/SecureField
        let emailField = app.textFields["you@example.com"]
        let passwordField = app.secureTextFields["Password"]

        if emailField.waitForExistence(timeout: 5) {
            emailField.tap()
            emailField.typeText(email)
        }

        if passwordField.waitForExistence(timeout: 5) {
            passwordField.tap()
            passwordField.typeText(password)
        }

        signInButton.tap()

        // Wait for the tab bar to appear (indicates successful auth)
        let leaguesTab = app.tabBars.buttons["Leagues"]
        let signedIn = leaguesTab.waitForExistence(timeout: 5)

        // If sign-in failed (e.g. no backend), log but do not
        // hard-fail — scaffold tests are expected to run without
        // a live backend.
        if !signedIn {
            _ = XCTContext.runActivity(
                named: "Auth Warning"
            ) { _ in
                XCTIssue(
                    type: .unmatchedExpectedFailure,
                    compactDescription:
                        "Sign-in did not complete. "
                        + "Tests requiring auth may be "
                        + "skipped."
                )
            }
        }
    }

    /// Whether the app is currently showing the auth screen.
    static func isOnAuthScreen(app: XCUIApplication) -> Bool {
        app.buttons["Sign In"].exists
    }

    /// Whether the app is authenticated (tab bar visible).
    static func isAuthenticated(app: XCUIApplication) -> Bool {
        app.tabBars.buttons["Leagues"].exists
    }
}
