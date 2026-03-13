import SwiftUI

/// Official Google "G" logo rendered as SwiftUI shapes.
/// Follows Google brand guidelines colour scheme.
struct GoogleGLogo: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius = size / 2
            let innerRadius = size * 0.28
            let barHeight = size * 0.16

            ZStack {
                // Blue arc (right: -45° to 45°)
                arcSegment(
                    center: center,
                    outerRadius: outerRadius,
                    innerRadius: innerRadius,
                    startAngle: -45,
                    endAngle: 45,
                    color: Color(red: 0.26, green: 0.52, blue: 0.96)
                )

                // Green arc (bottom-right: 45° to 135°)
                arcSegment(
                    center: center,
                    outerRadius: outerRadius,
                    innerRadius: innerRadius,
                    startAngle: 45,
                    endAngle: 135,
                    color: Color(red: 0.20, green: 0.66, blue: 0.33)
                )

                // Yellow arc (bottom-left: 135° to 225°)
                arcSegment(
                    center: center,
                    outerRadius: outerRadius,
                    innerRadius: innerRadius,
                    startAngle: 135,
                    endAngle: 225,
                    color: Color(red: 0.98, green: 0.74, blue: 0.02)
                )

                // Red arc (top: 225° to 315°)
                arcSegment(
                    center: center,
                    outerRadius: outerRadius,
                    innerRadius: innerRadius,
                    startAngle: 225,
                    endAngle: 315,
                    color: Color(red: 0.92, green: 0.26, blue: 0.21)
                )

                // Horizontal bar (right half of the G)
                Rectangle()
                    .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                    .frame(
                        width: outerRadius,
                        height: barHeight
                    )
                    .position(
                        x: center.x + outerRadius * 0.25,
                        y: center.y
                    )
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func arcSegment(
        center: CGPoint,
        outerRadius: CGFloat,
        innerRadius: CGFloat,
        startAngle: Double,
        endAngle: Double,
        color: Color
    ) -> some View {
        Path { path in
            path.addArc(
                center: center,
                radius: outerRadius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: .degrees(endAngle),
                endAngle: .degrees(startAngle),
                clockwise: true
            )
            path.closeSubpath()
        }
        .fill(color)
    }
}
