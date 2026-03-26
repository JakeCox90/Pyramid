import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class TokenSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    func testColorSwatches() {
        let view = VStack(alignment: .leading, spacing: 8) {
            swatchRow("Primary", Theme.Color.Primary.resting)
            swatchRow("Secondary", Theme.Color.Secondary.resting)
            swatchRow("Success", Theme.Color.Status.Success.resting)
            swatchRow("Error", Theme.Color.Status.Error.resting)
            swatchRow("Warning", Theme.Color.Status.Warning.resting)
            swatchRow("Surface/Page", Theme.Color.Surface.Background.page)
            swatchRow(
                "Surface/Container",
                Theme.Color.Surface.Background.container
            )
            swatchRow(
                "Surface/Elevated",
                Theme.Color.Surface.Background.elevated
            )
            swatchRow("Text/Default", Theme.Color.Content.Text.default)
            swatchRow("Text/Subtle", Theme.Color.Content.Text.subtle)
        }
        .padding()
        .background(Theme.Color.Surface.Background.page)
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 400)
            )
        )
    }

    func testSpacingScale() {
        let spacings: [(String, CGFloat)] = [
            ("s10 (4)", Theme.Spacing.s10),
            ("s20 (8)", Theme.Spacing.s20),
            ("s30 (12)", Theme.Spacing.s30),
            ("s40 (16)", Theme.Spacing.s40),
            ("s50 (20)", Theme.Spacing.s50),
            ("s60 (24)", Theme.Spacing.s60),
            ("s70 (32)", Theme.Spacing.s70),
            ("s80 (44)", Theme.Spacing.s80)
        ]
        let view = VStack(alignment: .leading, spacing: 6) {
            ForEach(spacings, id: \.0) { label, value in
                HStack(spacing: 8) {
                    Text(label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                        .frame(
                            width: 80,
                            alignment: .trailing
                        )
                    Rectangle()
                        .fill(Theme.Color.Primary.resting)
                        .frame(width: value, height: 12)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 2
                            )
                        )
                }
            }
        }
        .padding()
        .background(Theme.Color.Surface.Background.page)
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 300)
            )
        )
    }

    func testTypographyScale() {
        let view = VStack(alignment: .leading, spacing: 8) {
            Text("Display").font(Theme.Typography.display)
            Text("H1 Heading").font(Theme.Typography.h1)
            Text("H2 Heading").font(Theme.Typography.h2)
            Text("H3 Heading").font(Theme.Typography.h3)
            Text("Subhead").font(Theme.Typography.subhead)
            Text("Body Text").font(Theme.Typography.body)
            Text("Caption").font(Theme.Typography.caption)
            Text("OVERLINE").font(Theme.Typography.overline)
            Text("LABEL 01").font(Theme.Typography.label01)
        }
        .foregroundStyle(Theme.Color.Content.Text.default)
        .padding()
        .background(Theme.Color.Surface.Background.page)
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 500)
            )
        )
    }

    // MARK: - Helpers

    private func swatchRow(
        _ label: String,
        _ color: Color
    ) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 40, height: 28)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
            Spacer()
        }
    }
}
