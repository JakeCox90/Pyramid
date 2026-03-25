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
    let currentUserId: String?

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
            let msg = error.localizedDescription
            if msg.contains("schema cache") ||
                msg.contains("relation") ||
                msg.contains("does not exist") {
                // Table not yet available — show empty
                cards = []
            } else {
                errorMessage = msg
            }
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

}
