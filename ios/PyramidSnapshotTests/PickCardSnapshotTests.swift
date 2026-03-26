import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class PickCardSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    // MARK: - MatchCarouselCard (Large)

    func testCarouselDefault() {
        let view = MatchCarouselCard(
            fixture: SnapshotStubs.arsenalVsVilla,
            selectedTeamId: nil,
            usedTeamIds: [],
            usedTeamRounds: [:],
            isLocked: false,
            isSubmitting: false,
            onPick: { _, _ in }
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 500
                )
            )
        )
    }

    func testCarouselTeamSelected() {
        let view = MatchCarouselCard(
            fixture: SnapshotStubs.arsenalVsVilla,
            selectedTeamId: 42,
            usedTeamIds: [],
            usedTeamRounds: [:],
            isLocked: false,
            isSubmitting: false,
            onPick: { _, _ in }
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 500
                )
            )
        )
    }

    func testCarouselUsedTeam() {
        let view = MatchCarouselCard(
            fixture: SnapshotStubs.arsenalVsVilla,
            selectedTeamId: nil,
            usedTeamIds: [42],
            usedTeamRounds: [42: 18],
            isLocked: false,
            isSubmitting: false,
            onPick: { _, _ in }
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 500
                )
            )
        )
    }

    func testCarouselLocked() {
        let view = MatchCarouselCard(
            fixture: SnapshotStubs.arsenalVsVilla,
            selectedTeamId: nil,
            usedTeamIds: [],
            usedTeamRounds: [:],
            isLocked: true,
            isSubmitting: false,
            onPick: { _, _ in }
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 500
                )
            )
        )
    }

    // MARK: - FixturePickRow (List)

    func testPickRowDefault() {
        let view = FixturePickRow(
            fixture: SnapshotStubs.arsenalVsVilla,
            selectedTeamId: nil,
            usedTeamIds: [],
            usedTeamRounds: [:],
            isLocked: false,
            isSubmitting: false,
            onPick: { _, _ in }
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 120
                )
            )
        )
    }

    func testPickRowSelected() {
        let view = FixturePickRow(
            fixture: SnapshotStubs.arsenalVsVilla,
            selectedTeamId: 42,
            usedTeamIds: [],
            usedTeamRounds: [:],
            isLocked: false,
            isSubmitting: false,
            onPick: { _, _ in }
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 120
                )
            )
        )
    }
}
