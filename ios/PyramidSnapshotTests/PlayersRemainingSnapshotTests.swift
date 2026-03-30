import SnapshotTesting
import SwiftUI
import XCTest
@testable import Pyramid

final class PlayersRemainingSnapshotTests: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: .all) {
            super.invokeTest()
        }
    }

    // MARK: - Surviving State

    func testSurvivingSmallLeague() {
        let view = PlayersRemainingCard(
            activeCount: 5,
            totalCount: 8,
            eliminatedThisWeek: 2,
            survivalStreak: 4,
            eliminatedGameweekId: nil,
            userStatus: .active,
            currentUserId: "me",
            members: Self.smallLeagueMembers
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 420)
            )
        )
    }

    func testSurvivingLargeLeague() {
        let view = PlayersRemainingCard(
            activeCount: 7,
            totalCount: 32,
            eliminatedThisWeek: 5,
            survivalStreak: 6,
            eliminatedGameweekId: nil,
            userStatus: .active,
            currentUserId: "me",
            members: Self.largeLeagueMembers
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 420)
            )
        )
    }

    func testAllPlayersStanding() {
        let view = PlayersRemainingCard(
            activeCount: 8,
            totalCount: 8,
            eliminatedThisWeek: 0,
            survivalStreak: 1,
            eliminatedGameweekId: nil,
            userStatus: .active,
            currentUserId: "me",
            members: Self.allActiveMembers
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 380)
            )
        )
    }

    // MARK: - Eliminated State

    func testEliminated() {
        let view = PlayersRemainingCard(
            activeCount: 5,
            totalCount: 12,
            eliminatedThisWeek: 3,
            survivalStreak: 4,
            eliminatedGameweekId: 29,
            userStatus: .eliminated,
            currentUserId: "me",
            members: Self.eliminatedMembers
        )
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 345, height: 420)
            )
        )
    }

    // MARK: - Test Data

    private static let smallLeagueMembers: [MemberSummary] = [
        MemberSummary(userId: "me", displayName: "Jake Cox", avatarURL: nil, status: .active),
        MemberSummary(userId: "u2", displayName: "Tom Wilson", avatarURL: nil, status: .active),
        MemberSummary(userId: "u3", displayName: "Sam Jones", avatarURL: nil, status: .active),
        MemberSummary(userId: "u4", displayName: "Mike Lee", avatarURL: nil, status: .active),
        MemberSummary(userId: "u5", displayName: "Alex Park", avatarURL: nil, status: .active),
        MemberSummary(userId: "u6", displayName: "Dan White", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u7", displayName: "Pete Brown", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u8", displayName: "Rob Green", avatarURL: nil, status: .eliminated),
    ]

    private static let largeLeagueMembers: [MemberSummary] = {
        var members = [
            MemberSummary(userId: "me", displayName: "Jake Cox", avatarURL: nil, status: .active),
            MemberSummary(userId: "u2", displayName: "Tom Wilson", avatarURL: nil, status: .active),
            MemberSummary(userId: "u3", displayName: "Sam Jones", avatarURL: nil, status: .active),
            MemberSummary(userId: "u4", displayName: "Mike Lee", avatarURL: nil, status: .active),
            MemberSummary(userId: "u5", displayName: "Alex Park", avatarURL: nil, status: .active),
            MemberSummary(userId: "u6", displayName: "Dan White", avatarURL: nil, status: .active),
            MemberSummary(userId: "u7", displayName: "Pete Brown", avatarURL: nil, status: .active),
        ]
        for i in 8...32 {
            members.append(MemberSummary(
                userId: "u\(i)", displayName: "Player \(i)",
                avatarURL: nil, status: .eliminated
            ))
        }
        return members
    }()

    private static let allActiveMembers: [MemberSummary] = [
        MemberSummary(userId: "me", displayName: "Jake Cox", avatarURL: nil, status: .active),
        MemberSummary(userId: "u2", displayName: "Tom Wilson", avatarURL: nil, status: .active),
        MemberSummary(userId: "u3", displayName: "Sam Jones", avatarURL: nil, status: .active),
        MemberSummary(userId: "u4", displayName: "Mike Lee", avatarURL: nil, status: .active),
        MemberSummary(userId: "u5", displayName: "Alex Park", avatarURL: nil, status: .active),
        MemberSummary(userId: "u6", displayName: "Dan White", avatarURL: nil, status: .active),
        MemberSummary(userId: "u7", displayName: "Pete Brown", avatarURL: nil, status: .active),
        MemberSummary(userId: "u8", displayName: "Rob Green", avatarURL: nil, status: .active),
    ]

    private static let eliminatedMembers: [MemberSummary] = [
        MemberSummary(userId: "u2", displayName: "Tom Wilson", avatarURL: nil, status: .active),
        MemberSummary(userId: "u3", displayName: "Sam Jones", avatarURL: nil, status: .active),
        MemberSummary(userId: "u4", displayName: "Mike Lee", avatarURL: nil, status: .active),
        MemberSummary(userId: "u5", displayName: "Alex Park", avatarURL: nil, status: .active),
        MemberSummary(userId: "u6", displayName: "Dan White", avatarURL: nil, status: .active),
        MemberSummary(userId: "me", displayName: "Jake Cox", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u7", displayName: "Pete Brown", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u8", displayName: "Rob Green", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u9", displayName: "Kai Smith", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u10", displayName: "Liam Day", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u11", displayName: "Noah Reed", avatarURL: nil, status: .eliminated),
        MemberSummary(userId: "u12", displayName: "Owen Hart", avatarURL: nil, status: .eliminated),
    ]
}
