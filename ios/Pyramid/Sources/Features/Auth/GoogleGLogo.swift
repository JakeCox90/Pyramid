import SwiftUI

/// Official Google "G" logo rendered as SwiftUI shapes.
/// Follows Google brand guidelines colour scheme.
struct GoogleGLogo: View {
    private struct ArcConfig {
        let startAngle: Double
        let endAngle: Double
        let color: Color
    }

    private static let arcs: [ArcConfig] = [
        ArcConfig(startAngle: -45, endAngle: 45, color: Color(red: 0.26, green: 0.52, blue: 0.96)),
        ArcConfig(startAngle: 45, endAngle: 135, color: Color(red: 0.20, green: 0.66, blue: 0.33)),
        ArcConfig(startAngle: 135, endAngle: 225, color: Color(red: 0.98, green: 0.74, blue: 0.02)),
        ArcConfig(startAngle: 225, endAngle: 315, color: Color(red: 0.92, green: 0.26, blue: 0.21))
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius = size / 2
            let innerRadius = size * 0.28

            ZStack {
                ForEach(0..<Self.arcs.count, id: \.self) { index in
                    let arc = Self.arcs[index]
                    arcPath(center: center, outer: outerRadius, inner: innerRadius, arc: arc)
                }

                Rectangle()
                    .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                    .frame(width: outerRadius, height: size * 0.16)
                    .position(x: center.x + outerRadius * 0.25, y: center.y)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func arcPath(
        center: CGPoint,
        outer: CGFloat,
        inner: CGFloat,
        arc: ArcConfig
    ) -> some View {
        Path { path in
            path.addArc(
                center: center,
                radius: outer,
                startAngle: .degrees(arc.startAngle),
                endAngle: .degrees(arc.endAngle),
                clockwise: false
            )
            path.addArc(
                center: center,
                radius: inner,
                startAngle: .degrees(arc.endAngle),
                endAngle: .degrees(arc.startAngle),
                clockwise: true
            )
            path.closeSubpath()
        }
        .fill(arc.color)
    }
}
