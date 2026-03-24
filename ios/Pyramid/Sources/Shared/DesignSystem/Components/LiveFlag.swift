import SwiftUI

// MARK: - LiveFlag

struct LiveFlag: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.s10) {
            PulsingDot()
            Text("LIVE")
                .font(Theme.Typography.overline)
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live")
    }
}
