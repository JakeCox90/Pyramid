import SwiftUI

struct PulsingDot: View {
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        Circle()
            .fill(Theme.Color.Status.Error.resting)
            .frame(width: 7, height: 7)
            .scaleEffect(reduceMotion ? 1.0 : (pulse ? 1.5 : 1.0))
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear {
                if !reduceMotion { pulse = true }
            }
            .accessibilityHidden(true)
    }
}
