import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class FlagSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    func testSuccessFlag() {
        let view = Flag(label: "Survived", variant: .success)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 150, height: 40)
            )
        )
    }

    func testErrorFlag() {
        let view = Flag(label: "Eliminated", variant: .error)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 150, height: 40)
            )
        )
    }

    func testWarningFlag() {
        let view = Flag(label: "Pending", variant: .warning)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 150, height: 40)
            )
        )
    }

    func testNeutralFlag() {
        let view = Flag(label: "FT", variant: .neutral)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 150, height: 40)
            )
        )
    }

    func testLiveFlag() {
        let view = LiveFlag()
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 100, height: 40)
            )
        )
    }
}
