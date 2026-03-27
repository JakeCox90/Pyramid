import Foundation
import Sentry

/// Centralised crash reporting wrapper around Sentry SDK.
/// All Sentry interaction flows through this type — no direct Sentry imports elsewhere.
enum CrashReporter {

    // MARK: - Lifecycle

    /// Call once in `didFinishLaunchingWithOptions`, before any other SDK init.
    static func start() {
        guard let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String,
              !dsn.isEmpty else {
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.enableAutoSessionTracking = true
            options.enableCrashHandler = true
            options.enableAutoPerformanceTracing = true
            options.tracesSampleRate = 0.2
            options.attachScreenshot = true
            #if DEBUG
            options.environment = "dev"
            options.debug = true
            #else
            options.environment = "production"
            #endif
            options.beforeSend = { event in
                // Strip PII from breadcrumbs — keep URL paths but remove query params
                event.breadcrumbs = event.breadcrumbs?.map { crumb in
                    if var data = crumb.data,
                       let urlString = data["url"] as? String,
                       var components = URLComponents(string: urlString) {
                        components.query = nil
                        data["url"] = components.string
                        crumb.data = data
                    }
                    return crumb
                }
                return event
            }
        }
    }

    // MARK: - User Context

    /// Set after successful auth. Sentry uses this to group crashes by user.
    static func setUser(id: String) {
        let sentryUser = User(userId: id)
        SentrySDK.setUser(sentryUser)
    }

    /// Clear on sign-out.
    static func clearUser() {
        SentrySDK.setUser(nil)
    }

    // MARK: - Error Capture

    /// Capture a non-fatal error with optional context tags.
    static func capture(
        _ error: Error,
        context: [String: String] = [:]
    ) {
        let event = Event(error: error)
        event.tags = context
        SentrySDK.capture(event: event)
    }

    /// Capture a message (non-error) for visibility in the Sentry dashboard.
    static func captureMessage(
        _ message: String,
        level: SentryLevel = .info,
        context: [String: String] = [:]
    ) {
        let event = Event(level: level)
        event.message = SentryMessage(formatted: message)
        event.tags = context
        SentrySDK.capture(event: event)
    }

    // MARK: - Breadcrumbs

    /// Add a navigation breadcrumb for screen transitions.
    static func addBreadcrumb(
        category: String,
        message: String,
        data: [String: Any]? = nil
    ) {
        let crumb = Breadcrumb(level: .info, category: category)
        crumb.message = message
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }
}
