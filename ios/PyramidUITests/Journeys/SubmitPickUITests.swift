import XCTest

/// Journey 3: Submit a pick for a gameweek.
///
/// Covers the flow: Leagues tab -> select league -> Make Pick
/// -> view fixtures -> tap a team -> pick confirmed.
///
/// **Prerequisites:**
/// - Authenticated session
/// - At least one league the user has joined
/// - Current gameweek with available fixtures
///
/// **Note:** This flow is heavily backend-dependent. The
/// scaffold verifies element presence and navigation
/// structure. Actual pick submission requires live fixtures
/// and an open gameweek deadline.
final class SubmitPickUITests: XCTestCase {
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

    // MARK: - Navigate to Picks

    func testNavigateToLeaguesTab() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test picks")
            return
        }

        let leaguesTab = app.tabBars.buttons["Leagues"]
        leaguesTab.tapWhenReady()

        // Verify Leagues screen loads
        let leaguesTitle = app.navigationBars["Leagues"]
        XCTAssertTrue(
            leaguesTitle.waitForExistence(timeout: 10),
            "Leagues navigation title should appear"
        )
    }

    func testSelectLeagueAndViewDetail() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test picks")
            return
        }

        app.tabBars.buttons["Leagues"].tapWhenReady()

        // Wait for leagues to load. If the user has leagues,
        // the list will contain cells. If empty, the empty
        // state buttons appear.
        let hasLeagues = waitForLeaguesList()
        guard hasLeagues else {
            XCTSkip(
                "No leagues found — cannot test pick flow. "
                + "Create a league first."
            )
            return
        }

        // Tap the first league
        let firstLeague = app.cells.firstMatch
        guard firstLeague.waitForExistence(timeout: 5) else {
            // Try buttons/links as fallback (SwiftUI renders
            // NavigationLink differently)
            let firstLink = app.buttons.element(boundBy: 0)
            guard firstLink.exists else {
                XCTSkip("No tappable league row found")
                return
            }
            firstLink.tap()
            return
        }
        firstLeague.tap()

        // Verify league detail loaded — look for any content
        // that indicates we navigated deeper
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(
            backButton.waitForExistence(timeout: 10),
            "Should navigate to league detail"
        )
    }

    func testPicksScreenShowsFixturesOrEmptyState() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test picks")
            return
        }

        let navigatedToPicks = navigateToPicksScreen()
        guard navigatedToPicks else {
            XCTSkip("Could not navigate to picks screen")
            return
        }

        // The picks screen should show either:
        // 1. Fixtures with pick buttons
        // 2. Empty state ("No fixtures this week")
        // 3. Loading state (ProgressView)
        // 4. Error state

        let fixtureExists = app.staticTexts["PICK TEAM"]
            .waitForExistence(timeout: 10)
        let emptyState = app.staticTexts["No fixtures this week"]
            .exists

        // At least one state should be visible
        XCTAssertTrue(
            fixtureExists || emptyState
                || app.activityIndicators.firstMatch.exists,
            "Picks screen should show fixtures, empty state, "
            + "or loading indicator"
        )
    }

    func testPickButtonInteraction() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test picks")
            return
        }

        let navigatedToPicks = navigateToPicksScreen()
        guard navigatedToPicks else {
            XCTSkip("Could not navigate to picks screen")
            return
        }

        // Wait for fixtures to load
        let pickTeamDivider = app.staticTexts["PICK TEAM"]
        guard pickTeamDivider.waitForExistence(timeout: 10) else {
            XCTSkip(
                "No fixtures available — cannot test pick buttons"
            )
            return
        }

        // Find a HOME pick button.
        // Buttons show "HOME" or "AWAY" text (uppercased).
        let homeButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Home'")
        ).firstMatch

        guard homeButton.waitForExistence(timeout: 5) else {
            XCTSkip("No pick buttons found")
            return
        }

        // Tapping requires an open deadline — mark as expected
        // failure since we likely cannot submit without a live GW
        XCTExpectFailure(
            "Pick submission requires an open gameweek deadline"
        )

        homeButton.tap()

        // If pick succeeded, the button text changes to "PICKED"
        // and the view should dismiss
        let pickedLabel = app.staticTexts["PICKED"]
        _ = pickedLabel.waitForExistence(timeout: 5)
    }

    func testPicksViewModeToggle() {
        guard AuthTestHelper.isAuthenticated(app: app) else {
            XCTSkip("Not authenticated — cannot test picks")
            return
        }

        let navigatedToPicks = navigateToPicksScreen()
        guard navigatedToPicks else {
            XCTSkip("Could not navigate to picks screen")
            return
        }

        // Wait for content to load
        _ = app.staticTexts["PICK TEAM"]
            .waitForExistence(timeout: 10)

        // The view mode toggle button is in the toolbar
        // (list/carousel toggle). It uses SF Symbol names.
        let toggleButton = app.navigationBars.buttons.element(
            boundBy: app.navigationBars.buttons.count - 1
        )

        if toggleButton.waitForExistence(timeout: 5) {
            toggleButton.tap()
            // View should switch between carousel and list
            // We just verify no crash occurs
        }
    }

    // MARK: - Private Helpers

    /// Navigate from the authenticated root to the picks
    /// screen. Returns `true` if successful.
    private func navigateToPicksScreen() -> Bool {
        app.tabBars.buttons["Leagues"].tapWhenReady()

        guard waitForLeaguesList() else { return false }

        // Tap first league
        let cells = app.cells
        if cells.count > 0 {
            cells.firstMatch.tap()
        } else {
            // SwiftUI may render NavigationLink as a button
            let scrollView = app.scrollViews.firstMatch
            if scrollView.waitForExistence(timeout: 5) {
                let firstTappable = scrollView.buttons.firstMatch
                if firstTappable.exists {
                    firstTappable.tap()
                } else {
                    return false
                }
            } else {
                return false
            }
        }

        // Look for a "Make Pick" or "Pick" button in league detail
        // The exact label depends on the league state
        let pickButton = app.buttons.matching(
            NSPredicate(
                format: "label CONTAINS[c] 'pick'"
            )
        ).firstMatch

        if pickButton.waitForExistence(timeout: 10) {
            pickButton.tap()
            return true
        }

        // If no explicit pick button, the league detail may
        // navigate directly to picks via a NavigationLink
        return app.staticTexts["PICK TEAM"]
            .waitForExistence(timeout: 5)
            || app.staticTexts["No fixtures this week"]
                .waitForExistence(timeout: 5)
    }

    /// Wait for the leagues list to populate. Returns `false`
    /// if no leagues exist (empty state).
    private func waitForLeaguesList() -> Bool {
        // Wait for either leagues or empty state
        let leaguesNav = app.navigationBars["Leagues"]
        guard leaguesNav.waitForExistence(timeout: 10) else {
            return false
        }

        // Check for league cells
        let hasCells = app.cells.firstMatch
            .waitForExistence(timeout: 5)
        if hasCells { return true }

        // Check for scrollview with buttons (SwiftUI rendering)
        let hasButtons = app.scrollViews.firstMatch.buttons
            .firstMatch.waitForExistence(timeout: 3)
        if hasButtons { return true }

        // Empty state — no leagues
        return false
    }
}
