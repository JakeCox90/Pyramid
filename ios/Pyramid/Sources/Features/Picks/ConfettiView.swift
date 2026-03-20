import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    private let colors: [Color] = [
        Theme.Color.Status.Success.resting,
        Theme.Color.Primary.resting,
        Theme.Color.Status.Warning.resting,
        .white
    ]

    var body: some View {
        if reduceMotion {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Status.Success.resting)
                .allowsHitTesting(false)
        } else {
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.x, y: isAnimating ? particle.endY : particle.startY)
                        .opacity(isAnimating ? 0 : 1)
                        .rotationEffect(.degrees(isAnimating ? particle.rotation : 0))
                }
            }
            .onAppear {
                particles = (0..<30).map { _ in
                    ConfettiParticle(
                        color: colors.randomElement() ?? .white,
                        size: CGFloat.random(in: 4...8),
                        x: CGFloat.random(in: -150...150),
                        startY: CGFloat.random(in: -20...20),
                        endY: CGFloat.random(in: -300 ... -100),
                        rotation: Double.random(in: -360...360)
                    )
                }
                withAnimation(.easeOut(duration: 1.2)) {
                    isAnimating = true
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let rotation: Double
}
