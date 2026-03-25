import Foundation

// MARK: - Card Assembly

extension GameweekStoryViewModel {
    func buildCards(
        story: GameweekStory?,
        members: [LeagueMember],
        picks: [MemberPick],
        upsetFixture: Fixture?,
        wildcardPick: Pick?
    ) -> [StoryCard] {
        var result: [StoryCard] = []

        let stillStanding = members.filter {
            $0.status == .active || $0.status == .winner
        }
        let eliminatedThisWeek = members.filter {
            $0.eliminatedInGameweekId == gameweek
                && $0.status == .eliminated
        }
        let totalCount = members.count

        result.append(.title(
            leagueName: leagueName,
            gameweek: gameweek,
            aliveCount: stillStanding.count,
            totalCount: totalCount
        ))

        appendNarrativeCards(
            &result, story: story, picks: picks,
            eliminatedThisWeek: eliminatedThisWeek,
            upsetFixture: upsetFixture,
            wildcardPick: wildcardPick,
            members: members
        )

        let userStatus = appendUserPickCard(
            &result, picks: picks, members: members
        )

        appendStandingCard(
            &result, stillStanding: stillStanding,
            totalCount: totalCount,
            userStatus: userStatus
        )

        return result
    }

    // swiftlint:disable:next function_parameter_count
    private func appendNarrativeCards(
        _ result: inout [StoryCard],
        story: GameweekStory?,
        picks: [MemberPick],
        eliminatedThisWeek: [LeagueMember],
        upsetFixture: Fixture?,
        wildcardPick: Pick?,
        members: [LeagueMember]
    ) {
        if let headline = story?.headline,
           let body = story?.body {
            result.append(.headline(
                headline: headline, body: body
            ))
        }

        if let fixture = upsetFixture {
            let elimCount = eliminatedThisWeek
                .filter { m in
                    picks.first {
                        $0.userId == m.userId
                    }?.fixtureId == fixture.id
                }.count
            result.append(.upset(
                fixture: fixture,
                eliminationCount: max(elimCount, 1)
            ))
        }

        appendEliminationCards(
            &result, picks: picks,
            eliminatedThisWeek: eliminatedThisWeek,
            isMassElim: story?.isMassElimination ?? false
        )

        if let wcPick = wildcardPick {
            let wcMember = members.first {
                $0.userId == wcPick.userId
            }
            result.append(.wildcard(
                player: WildcardPlayer(
                    displayName: wcMember?.profiles
                        .displayLabel ?? "Unknown",
                    teamName: wcPick.teamName,
                    result: wcPick.teamName,
                    survived: wcPick.result == .survived
                )
            ))
        }
    }

    private func appendEliminationCards(
        _ result: inout [StoryCard],
        picks: [MemberPick],
        eliminatedThisWeek: [LeagueMember],
        isMassElim: Bool
    ) {
        if !eliminatedThisWeek.isEmpty {
            let elimPlayers = eliminatedThisWeek
                .map { member in
                    let pick = picks.first {
                        $0.userId == member.userId
                    }
                    let isAuto = pick == nil
                    return EliminatedPlayer(
                        id: member.userId,
                        displayName: member.profiles
                            .displayLabel,
                        teamName: pick?.teamName ?? "—",
                        result: isAuto
                            ? "Missed deadline"
                            : (pick?.teamName ?? "—"),
                        isAutoEliminated: isAuto
                    )
                }
            result.append(
                .eliminated(players: elimPlayers)
            )
        }

        if isMassElim {
            result.append(.massElimination(
                playerCount: eliminatedThisWeek.count
            ))
        }
    }

    @discardableResult
    private func appendUserPickCard(
        _ result: inout [StoryCard],
        picks: [MemberPick],
        members: [LeagueMember]
    ) -> UserStoryStatus {
        let userPick = picks.first {
            $0.userId == currentUserId
        }
        let userMember = members.first {
            $0.userId == currentUserId
        }
        let userStatus: UserStoryStatus = {
            if userMember?.status == .winner {
                return .winner
            }
            if userPick == nil
                && userMember?.eliminatedInGameweekId
                    == gameweek {
                return .missedDeadline
            }
            if userPick?.result == .void {
                return .voidSurvived
            }
            if userPick?.result == .eliminated {
                return .eliminated
            }
            return .survived
        }()

        result.append(.yourPick(pick: YourPickResult(
            teamName: userPick?.teamName,
            teamId: userPick?.teamId,
            result: userPick?.result.rawValue,
            status: userStatus
        )))
        return userStatus
    }

    private func appendStandingCard(
        _ result: inout [StoryCard],
        stillStanding: [LeagueMember],
        totalCount: Int,
        userStatus: UserStoryStatus
    ) {
        let standingPlayers = stillStanding.map { member in
            StandingPlayer(
                id: member.userId,
                displayName: member.profiles.displayLabel,
                isCurrentUser: member.userId
                    == currentUserId
            )
        }

        result.append(.standing(
            players: standingPlayers,
            totalCount: totalCount,
            userStatus: userStatus
        ))
    }
}
