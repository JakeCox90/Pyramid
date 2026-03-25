import Foundation

/// Feature flags with compile-time defaults and DEBUG runtime overrides.
/// Controlled via OTHER_SWIFT_FLAGS in .xcconfig files.
enum FeatureFlags {
    /// Whether paid leagues, wallet, and financial features are enabled.
    /// In DEBUG builds, a runtime toggle in Developer Tools can override this.
    /// In Release builds, controlled solely by -DPAID_FEATURES_ENABLED.
    static var paidFeaturesEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.object(
            forKey: "debug_paid_features"
        ) as? Bool ?? compiledDefault
        #else
        return compiledDefault
        #endif
    }

    #if DEBUG
    /// Sets the runtime override for paid features (DEBUG only).
    static func setPaidFeaturesOverride(_ enabled: Bool) {
        UserDefaults.standard.set(
            enabled,
            forKey: "debug_paid_features"
        )
    }
    #endif

    // MARK: - Private

    private static var compiledDefault: Bool {
        #if PAID_FEATURES_ENABLED
        return true
        #else
        return false
        #endif
    }
}
