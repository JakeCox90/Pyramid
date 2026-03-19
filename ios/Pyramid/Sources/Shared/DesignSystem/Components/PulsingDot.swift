import SwiftUI

struct PulsingDot: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Theme.Color.Status.Error.resting)
            .frame(width: 7, height: 7)
            .scaleEffect(pulse ? 1.5 : 1.0)
            .animation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = true }
    }
}
