import Foundation

@MainActor
final class GameweekStoryViewModel: ObservableObject {
    @Published var cards: [StoryCard] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasBeenViewed = false
    @Published var showOverview = false

    let leagueId: String
    let gameweek: Int
    let leagueName: String

    private let storyService: GameweekStoryServiceProtocol
    private let standingsService: StandingsServiceProtocol
    private let currentUserId: String?

    init(
        leagueId: String,
        gameweek: Int,
        leagueName: String,
        storyService: GameweekStoryServiceProtocol = GameweekStoryService(),
        standingsService: StandingsServiceProtocol = StandingsService(),
        currentUserId: String? = nil
    ) {
        self.leagueId = leagueId
        self.gameweek = gameweek
        self.leagueName = leagueName
        self.storyService = storyService
        self.standingsService = standingsService
        self.currentUserId = currentUserId
    }

    var totalCards: Int { cards.count }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let storyFetch = storyService.fetchStory(leagueId: leagueId, gameweekId: gameweek)
            async let membersFetch = standingsService.fetchMembers(leagueId: leagueId)
            async let picksFetch = standingsService.fetchLockedPicks(leagueId: leagueId, gameweekId: gameweek)
            async let viewedFetch = storyService.fetchStoryViewed(leagueId: leagueId, gameweekId: gameweek)

            let story = try await storyFetch
            let members = try await membersFetch
            let picks = try await picksFetch
            hasBeenViewed = try await viewedFetch

            var upsetFixture: Fixture?
            if let upsetId = story?.upsetFixtureId {
                upsetFixture = try? await storyService.fetchUpsetFixture(fixtureId: upsetId)
            }

            var wildcardPick: Pick?
            if let wcId = story?.wildcardPickId {
                wildcardPick = try? await storyService.fetchWildcardPick(pickId: wcId)
            }

            cards = buildCards(
                story: story, members: members, picks: picks,
                upsetFixture: upsetFixture, wildcardPick: wildcardPick
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func advance() {
        guard currentIndex < totalCards - 1 else {
            showOverview = true
            return
        }
        currentIndex += 1
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func markViewed() async {
        guard !hasBeenViewed else { return }
        try? await storyService.markStoryViewed(leagueId: leagueId, gameweekId: gameweek)
        hasBeenViewed = true
    }

    // MARK: - Card Assembly

    private func buildCards(
        story: GameweekStory?,
        members: [LeagueMember],
        picks: [MemberPick],
        upsetFixture: Fixture?,
        wildcardPick: Pick?
    ) -> [StoryCard] {
        var result: [StoryCard] = []

        let stillStanding = members.filter { $0.status == .active || $0.status == .winner }
        let eliminatedThisWeek = members.filter {
            $0.eliminatedInGameweekId == gameweek && $0.status == .eliminated
        }
        let totalCount = members.count
        let isMassElim = story?.isMassElimination ?? false

        // 1. Title (always)
        result.append(.title(
            leagueName: leagueName,
            gameweek: gameweek,
            aliveCount: stillStanding.count,
            totalCount: totalCount
        ))

        // 2. Headline (if story exists with headline)
        if let headline = story?.headline, let body = story?.body {
            result.append(.headline(headline: headline, body: body))
        }

        // 3. Biggest Upset (if upset fixture was fetched)
        if let fixture = upsetFixture {
            let elimCount = eliminatedThisWeek.filter { member in
                picks.first { $0.userId == member.userId }?.fixtureId == fixture.id
            }.count
            result.append(.upset(fixture: fixture, eliminationCount: max(elimCount, 1)))
        }

        // 4. Eliminated (if any eliminated this week)
        if !eliminatedThisWeek.isEmpty {
            let elimPlayers = eliminatedThisWeek.map { member -> EliminatedPlayer in
                let pick = picks.first { $0.userId == member.userId }
                let isAuto = pick == nil
                return EliminatedPlayer(
                    id: member.userId,
                    displayName: member.profiles.displayLabel,
                    teamName: pick?.teamName ?? "—",
                    result: isAuto ? "Missed deadline" : (pick?.teamName ?? "—"),
                    isAutoEliminated: isAuto
                )
            }
            result.append(.eliminated(players: elimPlayers))
        }

        // 4b. Mass elimination card
        if isMassElim {
            result.append(.massElimination(playerCount: eliminatedThisWeek.count))
        }

        // 5. Wildcard
        if let wcPick = wildcardPick {
            let wcMember = members.first { $0.userId == wcPick.userId }
            result.append(.wildcard(player: WildcardPlayer(
                displayName: wcMember?.profiles.displayLabel ?? "Unknown",
                teamName: wcPick.teamName,
                result: wcPick.teamName,
                survived: wcPick.result == .survived
            )))
        }

        // 6. Your Pick (always)
        let userPick = picks.first { $0.userId == currentUserId }
        let userMember = members.first { $0.userId == currentUserId }
        let userStatus: UserStoryStatus = {
            if userMember?.status == .winner { return .winner }
            if userPick == nil && userMember?.eliminatedInGameweekId == gameweek { return .missedDeadline }
            if userPick?.result == .void { return .voidSurvived }
            if userPick?.result == .eliminated { return .eliminated }
            return .survived
        }()

        result.append(.yourPick(pick: YourPickResult(
            teamName: userPick?.teamName,
            teamId: userPick?.teamId,
            result: userPick?.teamName,
            status: userStatus
        )))

        // 7. Standing (always)
        let standingPlayers = stillStanding.map { member in
            StandingPlayer(
                id: member.userId,
                displayName: member.profiles.displayLabel,
                isCurrentUser: member.userId == currentUserId
            )
        }

        result.append(.standing(
            players: standingPlayers,
            totalCount: totalCount,
            userStatus: userStatus
        ))

        return result
    }
}
