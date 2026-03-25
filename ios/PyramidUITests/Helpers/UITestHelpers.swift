import XCTest

// MARK: - UI Test Configuration

/// Environment variable keys injected via the Xcode scheme or
/// CI workflow to control test behaviour.
enum UITestEnv {
    static let testEmail = "UI_TEST_EMAIL"
    static let testPassword = "UI_TEST_PASSWORD"
    static let skipOnboarding = "UI_TEST_SKIP_ONBOARDING"
    static let isUITest = "UI_TEST_RUNNING"
}

// MARK: - XCUIApplication Helpers

extension XCUIApplication {
    /// Launch the app configured for UI testing.
    ///
    /// Uses environment variables to inject test credentials
    /// so tests do not contain hardcoded secrets.
    ///
    /// **Running locally:**
    /// ```
    /// # Set env vars before running from Xcode or CLI:
    /// export UI_TEST_EMAIL="uitest@example.com"
    /// export UI_TEST_PASSWORD="TestPassword123!"
    /// ```
    ///
    /// **Running in CI:**
    /// Credentials come from GitHub Secrets and are injected
    /// by the `ios-ci.yml` workflow step.
    func launchForTesting(
        additionalArgs: [String] = [],
        additionalEnv: [String: String] = [:]
    ) {
        launchArguments = ["-UITesting"] + additionalArgs
        launchEnvironment = [
            UITestEnv.isUITest: "1",
            UITestEnv.skipOnboarding: "1"
        ]

        // Merge test credentials from host environment
        if let email = ProcessInfo.processInfo.environment[UITestEnv.testEmail] {
            launchEnvironment[UITestEnv.testEmail] = email
        }
        if let password = ProcessInfo.processInfo.environment[UITestEnv.testPassword] {
            launchEnvironment[UITestEnv.testPassword] = password
        }

        for (key, value) in additionalEnv {
            launchEnvironment[key] = value
        }

        launch()
    }
}

// MARK: - XCUIElement Helpers

extension XCUIElement {
    /// Wait for the element to exist within the given timeout,
    /// with a convenient default of 10 seconds.
    /// Returns `true` if found, `false` if timed out.
    @discardableResult
    func waitForElement(
        timeout: TimeInterval = 10
    ) -> Bool {
        waitForExistence(timeout: timeout)
    }

    /// Tap the element after waiting for it to exist.
    /// Fails the test if the element does not appear.
    func tapWhenReady(
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let found = waitForExistence(timeout: timeout)
        XCTAssertTrue(
            found,
            "Element \(identifier) did not appear within \(timeout)s",
            file: file,
            line: line
        )
        tap()
    }

    /// Type text into the element after tapping it.
    ///
    /// Clears existing content by sending one delete key per
    /// character — more reliable than the context-menu
    /// "Select All" approach which can fail on CI.
    func clearAndType(
        _ text: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        tapWhenReady(file: file, line: line)

        // Delete existing text character-by-character
        if let existingText = value as? String,
           !existingText.isEmpty {
            let deletes = String(
                repeating: XCUIKeyboardKey.delete.rawValue,
                count: existingText.count
            )
            typeText(deletes)
        }

        typeText(text)
    }
}
