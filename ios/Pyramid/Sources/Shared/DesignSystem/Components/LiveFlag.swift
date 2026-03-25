import SwiftUI

/// Convenience — `Flag(label: "LIVE", variant: .live)`
struct LiveFlag: View {
    var body: some View {
        Flag(label: "LIVE", variant: .live)
            .accessibilityLabel("Live")
    }
}
