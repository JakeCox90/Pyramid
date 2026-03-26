import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class ButtonSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    func testPrimary() {
        let view = Button("Submit Pick") {}
            .themed(.primary)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 60)
            )
        )
    }

    func testSecondary() {
        let view = Button("Cancel") {}
            .themed(.secondary)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 60)
            )
        )
    }

    func testDestructive() {
        let view = Button("Leave League") {}
            .themed(.destructive)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 60)
            )
        )
    }

    func testGhost() {
        let view = Button("Skip") {}
            .themed(.ghost)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 60)
            )
        )
    }

    func testLoading() {
        let view = Button("Loading...") {}
            .themed(.primary, isLoading: true)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 60)
            )
        )
    }

    func testDisabled() {
        let view = Button("Disabled") {}
            .themed(.primary)
            .disabled(true)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 60)
            )
        )
    }

    func testCompact() {
        let view = Button("Compact") {}
            .themed(.primary, fullWidth: false)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 200, height: 60)
            )
        )
    }
}
