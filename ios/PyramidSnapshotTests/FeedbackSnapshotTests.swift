import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class FeedbackSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    func testSuccessToast() {
        let config = ToastConfiguration(
            icon: "checkmark.circle.fill",
            title: "Pick submitted",
            subtitle: "Arsenal selected for GW20",
            style: .success
        )
        let view = Toast(config: config)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 70)
            )
        )
    }

    func testErrorToast() {
        let config = ToastConfiguration(
            icon: "xmark.circle.fill",
            title: "Pick failed",
            subtitle: "Please try again",
            style: .error
        )
        let view = Toast(config: config)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 70)
            )
        )
    }

    func testWarningToast() {
        let config = ToastConfiguration(
            icon: "exclamationmark.triangle.fill",
            title: "Deadline approaching",
            subtitle: "2 hours until lockout",
            style: .warning
        )
        let view = Toast(config: config)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 70)
            )
        )
    }
}
