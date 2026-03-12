import Foundation
import os

/// Structured logging using Apple's Unified Logging system (os_log).
/// Queryable via Console.app and included in crash reports.
///
/// Usage:
///   Log.auth.info("User signed in", metadata: ["userId": userId.prefix(8)])
///   Log.picks.error("Submit failed", metadata: ["leagueId": leagueId])
///   Log.wallet.info("Top-up initiated", metadata: ["amountPence": "\(amount)"])
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.pyramid.app"

    /// Authentication and session events
    static let auth = Logger(subsystem: subsystem, category: "auth")
    /// Pick submission and settlement events
    static let picks = Logger(subsystem: subsystem, category: "picks")
    /// Wallet operations (top-up, withdrawal, balance)
    static let wallet = Logger(subsystem: subsystem, category: "wallet")
    /// Push notification lifecycle
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    /// Network and Edge Function calls
    static let network = Logger(subsystem: subsystem, category: "network")
    /// League creation and joining
    static let leagues = Logger(subsystem: subsystem, category: "leagues")
    /// Home screen aggregate data fetching
    static let home = Logger(subsystem: subsystem, category: "home")
}
