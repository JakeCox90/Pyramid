import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class MatchCardSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    func testPreMatchUnlocked() {
        let view = MatchCard(
            pickedTeamName: "Arsenal",
            pickedTeamLogo: nil,
            opponentName: "Aston Villa",
            homeTeamName: "Arsenal",
            venue: "Emirates Stadium",
            kickoff: SnapshotStubs.tomorrow,
            phase: .preMatch,
            buttonTitle: "CHANGE PICK",
            onButtonTap: {}
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 446
                )
            )
        )
    }

    func testPreMatchLocked() {
        let view = MatchCard(
            pickedTeamName: "Arsenal",
            pickedTeamLogo: nil,
            opponentName: "Aston Villa",
            homeTeamName: "Arsenal",
            venue: "Emirates Stadium",
            kickoff: SnapshotStubs.tomorrow,
            phase: .preMatch,
            isLocked: true
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 446
                )
            )
        )
    }

    func testLive() {
        let view = MatchCard(
            pickedTeamName: "Liverpool",
            pickedTeamLogo: nil,
            opponentName: "Chelsea",
            homeTeamName: "Liverpool",
            homeScore: 2,
            awayScore: 1,
            phase: .live,
            isLocked: true
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 446
                )
            )
        )
    }

    func testFinishedSurvived() {
        let view = MatchCard(
            pickedTeamName: "Man City",
            pickedTeamLogo: nil,
            opponentName: "Tottenham",
            homeTeamName: "Man City",
            homeScore: 3,
            awayScore: 0,
            phase: .finished,
            survived: true,
            isLocked: true
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 446
                )
            )
        )
    }

    func testFinishedEliminated() {
        let view = MatchCard(
            pickedTeamName: "Man City",
            pickedTeamLogo: nil,
            opponentName: "Tottenham",
            homeTeamName: "Man City",
            homeScore: 1,
            awayScore: 2,
            phase: .finished,
            survived: false,
            isLocked: true
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 446
                )
            )
        )
    }

    func testEmpty() {
        let view = MatchCard.empty(
            isLocked: false,
            onMakePick: {}
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(
                    width: 345,
                    height: 446
                )
            )
        )
    }
}
