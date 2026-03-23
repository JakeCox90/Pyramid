import Foundation

/// Centralized accessibility identifiers for XCUITest element
/// selection. Every identifier used in UI tests must be defined
/// here to keep them in sync with production views.
enum AccessibilityID {
    // MARK: - Auth

    enum Auth {
        static let emailField = "auth.email.field"
        static let passwordField = "auth.password.field"
        static let signInButton = "auth.signIn.button"
        static let createAccountButton = "auth.createAccount.button"
        static let appleSignInButton = "auth.apple.button"
        static let googleSignInButton = "auth.google.button"
        static let errorMessage = "auth.error.message"
    }

    // MARK: - Main Tab Bar

    enum Tab {
        static let home = "tab.home"
        static let leagues = "tab.leagues"
        static let profile = "tab.profile"
    }

    // MARK: - Leagues

    enum Leagues {
        static let list = "leagues.list"
        static let createButton = "leagues.create.button"
        static let joinButton = "leagues.join.button"
        static let browseButton = "leagues.browse.button"
        static let addMenu = "leagues.add.menu"
        static let emptyState = "leagues.emptyState"
    }

    // MARK: - Create League

    enum CreateLeague {
        static let nameField = "createLeague.name.field"
        static let submitButton = "createLeague.submit.button"
        static let cancelButton = "createLeague.cancel.button"
    }

    // MARK: - League Created

    enum LeagueCreated {
        static let joinCode = "leagueCreated.joinCode"
        static let copyButton = "leagueCreated.copy.button"
        static let shareButton = "leagueCreated.share.button"
        static let doneButton = "leagueCreated.done.button"
    }

    // MARK: - League Detail

    enum LeagueDetail {
        static let makePickButton = "leagueDetail.makePick.button"
    }

    // MARK: - Picks

    enum Picks {
        static let fixtureRow = "picks.fixture.row"
        static let homePickButton = "picks.home.button"
        static let awayPickButton = "picks.away.button"
        static let gameweekHeader = "picks.gameweek.header"
    }
}
