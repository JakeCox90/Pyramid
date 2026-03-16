import Foundation

/// Compile-time feature flags.
/// Controlled via OTHER_SWIFT_FLAGS in .xcconfig files.
enum FeatureFlags {
    /// Whether paid leagues, wallet, and financial features are enabled.
    /// Controlled by -DPAID_FEATURES_ENABLED in OTHER_SWIFT_FLAGS.
    static var paidFeaturesEnabled: Bool {
        #if PAID_FEATURES_ENABLED
        return true
        #else
        return false
        #endif
    }
}
