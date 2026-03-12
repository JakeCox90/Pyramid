import SwiftUI

// MARK: - Theme Icon Tokens

// Usage: Theme.Icon.status.success, Theme.Icon.navigation.leagues, etc.
// All icon values are SF Symbol system names.

extension Theme {
    enum Icon {

        // MARK: - Navigation

        enum Navigation {
            static let home = "house.fill"
            static let leagues = "trophy"
            static let profile = "person.circle"
            static let notifications = "bell"
            static let notificationsDisabled = "bell.slash.fill"
            static let disclosure = "chevron.right"
            static let add = "plus"
        }

        // MARK: - League

        enum League {
            static let trophy = "trophy"
            static let trophyFill = "trophy.fill"
            static let trophyCircle = "trophy.circle.fill"
            static let members = "person.2"
            static let join = "person.badge.plus"
            static let create = "plus.circle"
            static let paid = "creditcard"
        }

        // MARK: - Pick

        enum Pick {
            static let gameweek = "calendar"
            static let deadline = "calendar.badge.clock"
            static let timeRemaining = "clock"
            static let locked = "lock.fill"
            static let pseudonymous = "theatermasks"
            static let noRepeat = "arrow.triangle.2.circlepath"
            static let history = "list.bullet.clipboard"
        }

        // MARK: - Wallet

        enum Wallet {
            static let empty = "creditcard"
            static let topUp = "arrow.down.circle.fill"
            static let withdrawal = "arrow.up.circle.fill"
            static let refund = "arrow.counterclockwise.circle.fill"
            static let winnings = "star.circle.fill"
        }

        // MARK: - Action

        enum Action {
            static let copy = "doc.on.doc"
            static let copied = "checkmark"
            static let share = "square.and.arrow.up"
        }

        // MARK: - Status

        enum Status {
            static let success = "checkmark.circle.fill"
            static let failure = "xmark.circle.fill"
            static let error = "exclamationmark.triangle"
            static let errorFill = "exclamationmark.triangle.fill"
            static let info = "info.circle.fill"
        }
    }
}
