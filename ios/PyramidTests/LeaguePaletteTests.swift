import XCTest
@testable import Pyramid

final class LeaguePaletteTests: XCTestCase {

    // MARK: - Raw Value

    func testPrimaryRawValue() {
        XCTAssertEqual(LeaguePalette.primary.rawValue, "primary")
    }

    // MARK: - Display Name

    func testPrimaryDisplayName() {
        XCTAssertEqual(LeaguePalette.primary.displayName, "Purple")
    }

    // MARK: - from(key:)

    func testFromValidKey() {
        XCTAssertEqual(
            LeaguePalette.from(key: "primary"),
            .primary
        )
    }

    func testFromUnknownKeyDefaultsToPrimary() {
        XCTAssertEqual(
            LeaguePalette.from(key: "unknown"),
            .primary
        )
    }

    func testFromEmptyKeyDefaultsToPrimary() {
        XCTAssertEqual(
            LeaguePalette.from(key: ""),
            .primary
        )
    }

    // MARK: - CaseIterable

    func testAllCasesContainsPrimary() {
        XCTAssertTrue(LeaguePalette.allCases.contains(.primary))
    }
}
