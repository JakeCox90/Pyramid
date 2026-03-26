import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class InputSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    func testDefault() {
        let view = InputField(
            label: "League Name",
            text: .constant(""),
            placeholder: "Enter league name"
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 90)
            )
        )
    }

    func testWithValue() {
        let view = InputField(
            label: "League Name",
            text: .constant("Sunday League"),
            placeholder: "Enter league name"
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 90)
            )
        )
    }

    func testWithError() {
        let view = InputField(
            label: "League Name",
            text: .constant(""),
            placeholder: "Enter league name",
            errorMessage: "League name is required"
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 110)
            )
        )
    }

    func testSecure() {
        let view = InputField(
            label: "Password",
            text: .constant("secret123"),
            placeholder: "Enter password",
            isSecure: true
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 90)
            )
        )
    }
}
