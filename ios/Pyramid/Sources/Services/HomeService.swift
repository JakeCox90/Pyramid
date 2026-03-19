import Foundation
import os
import Supabase

// MARK: - Private helper types

private struct HomeMemberRow: Decodable {
    let leagueId: String
    let status: LeagueMember.MemberStatus

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
        case status
    }
}

private struct HomeLeagueWithCountRow: Decodable {
    let id: String
    let name: String
    let joinCode: String
    let type: League.LeagueType
    let status: League.LeagueStatus
    let season: Int
    let createdAt: Date
    let leagueMembers: [HomeAggregateCount]

    enum CodingKeys: String, CodingKey {
        case id, name, type, status, season
        case joinCode = "join_code"
        case createdAt = "created_at"
        case leagueMembers = "league_members"
    }

    func toLeague() -> League {
        var league = League(
            id: id,
            name: name,
            joinCode: joinCode,
            type: type,
            status: status,
            season: season,
            createdAt: createdAt
        )
        league.memberCount = leagueMembers.first?.count ?? 0
        return league
    }
}

private struct HomeAggregateCount: Decodable {
    let count: Int
}

private struct HomeMemberIdRow: Decodable {
    let leagueId: String

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
    }
}

// MARK: - Protocol

protocol HomeServiceProtocol: Sendable {
    func fetchHomeData() async throws -> HomeData
    func fetchFixtures(gameweekId: Int) async throws -> [Fixture]
}

// MARK: - Implementation

final class HomeService: HomeServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchHomeData() async throws -> HomeData {
        let userId = try await client.auth.session.user.id.uuidString
        Log.home.info("Fetching home data for user")

        async let leaguesFetch = fetchLeaguesWithCounts(userId: userId)
        async let memberStatusesFetch = fetchMemberStatuses(userId: userId)
        async let gameweekFetch = fetchCurrentGameweek()
        async let lastGwFetch = fetchLastFinishedGameweek()

        let leagues = try await leaguesFetch
        let memberStatuses = try await memberStatusesFetch
        let gameweek = try await gameweekFetch
        let lastGw = try await lastGwFetch

        let leagueMap = Dictionary(
            uniqueKeysWithValues: leagues.map { ($0.id, $0.name) }
        )

        var picks: [String: Pick] = [:]
        var fixtures: [Int: Fixture] = [:]
        if let gw = gameweek {
            async let picksFetch = fetchPicks(
                userId: userId,
                gameweekId: gw.id,
                leagueIds: leagues.map(\.id)
            )
            async let fixturesFetch = fetchFixtures(gameweekId: gw.id)

            picks = try await picksFetch
            let fixturesList = try await fixturesFetch
            fixtures = Dictionary(
                uniqueKeysWithValues: fixturesList.map { ($0.id, $0) }
            )
        }

        var lastGwResults: [LeagueResult] = []
        if let lastGw, !leagues.isEmpty {
            lastGwResults = try await fetchLastGwResults(
                userId: userId,
                gameweek: lastGw,
                leagueIds: leagues.map(\.id),
                leagueNames: leagueMap
            )
        }

        Log.home.info("Home data fetched: \(leagues.count) leagues, gameweek=\(gameweek?.id ?? -1, privacy: .public)")
        return HomeData(
            leagues: leagues,
            gameweek: gameweek,
            picks: picks,
            memberStatuses: memberStatuses,
            fixtures: fixtures,
            lastGwResults: lastGwResults
        )
    }

    func fetchFixtures(gameweekId: Int) async throws -> [Fixture] {
        let rows: [Fixture] = try await client
            .from("fixtures")
            .select(
                """
                id, gameweek_id, home_team_id, home_team_name, \
                home_team_short, home_team_logo, away_team_id, \
                away_team_name, away_team_short, away_team_logo, \
                kickoff_at, status, home_score, away_score
                """
            )
            .eq("gameweek_id", value: gameweekId)
            .execute()
            .value

        return rows
    }

    // MARK: - Private helpers

    private func fetchLeaguesWithCounts(
        userId: String
    ) async throws -> [League] {
        let memberRows: [HomeMemberIdRow] = try await client
            .from("league_members")
            .select("league_id")
            .eq("user_id", value: userId)
            .execute()
            .value

        let leagueIds = memberRows.map(\.leagueId)
        guard !leagueIds.isEmpty else { return [] }

        let rows: [HomeLeagueWithCountRow] = try await client
            .from("leagues")
            .select(
                """
                id, name, join_code, type, status, season, \
                created_at, league_members(count)
                """
            )
            .in("id", values: leagueIds)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.map { $0.toLeague() }
    }

    private func fetchMemberStatuses(
        userId: String
    ) async throws -> [String: LeagueMember.MemberStatus] {
        let rows: [HomeMemberRow] = try await client
            .from("league_members")
            .select("league_id, status")
            .eq("user_id", value: userId)
            .execute()
            .value

        return Dictionary(
            uniqueKeysWithValues: rows.map { ($0.leagueId, $0.status) }
        )
    }

    private func fetchCurrentGameweek() async throws -> Gameweek? {
        let rows: [Gameweek] = try await client
            .from("gameweeks")
            .select(
                """
                id, season, round_number, name, \
                deadline_at, is_current, is_finished
                """
            )
            .eq("is_current", value: true)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    private func fetchLastFinishedGameweek() async throws -> Gameweek? {
        let rows: [Gameweek] = try await client
            .from("gameweeks")
            .select(
                """
                id, season, round_number, name, \
                deadline_at, is_current, is_finished
                """
            )
            .eq("is_finished", value: true)
            .order("round_number", ascending: false)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    private func fetchPicks(
        userId: String,
        gameweekId: Int,
        leagueIds: [String]
    ) async throws -> [String: Pick] {
        guard !leagueIds.isEmpty else { return [:] }

        let rows: [Pick] = try await client
            .from("picks")
            .select(
                """
                id, league_id, user_id, gameweek_id, fixture_id, \
                team_id, team_name, is_locked, result, submitted_at
                """
            )
            .eq("user_id", value: userId)
            .eq("gameweek_id", value: gameweekId)
            .in("league_id", values: leagueIds)
            .execute()
            .value

        return Dictionary(
            uniqueKeysWithValues: rows.map { ($0.leagueId, $0) }
        )
    }

    private func fetchLastGwResults(
        userId: String,
        gameweek: Gameweek,
        leagueIds: [String],
        leagueNames: [String: String]
    ) async throws -> [LeagueResult] {
        let picks: [Pick] = try await client
            .from("picks")
            .select(
                """
                id, league_id, user_id, gameweek_id, fixture_id, \
                team_id, team_name, is_locked, result, submitted_at
                """
            )
            .eq("user_id", value: userId)
            .eq("gameweek_id", value: gameweek.id)
            .in("league_id", values: leagueIds)
            .neq("result", value: "pending")
            .execute()
            .value

        guard !picks.isEmpty else { return [] }

        let fixtureIds = picks.map(\.fixtureId)
        let fixtures: [Fixture] = try await client
            .from("fixtures")
            .select(
                """
                id, gameweek_id, home_team_id, home_team_name, \
                home_team_short, home_team_logo, away_team_id, \
                away_team_name, away_team_short, away_team_logo, \
                kickoff_at, status, home_score, away_score
                """
            )
            .in("id", values: fixtureIds)
            .execute()
            .value

        let fixtureMap = Dictionary(
            uniqueKeysWithValues: fixtures.map { ($0.id, $0) }
        )

        return picks.compactMap { pick in
            guard let fixture = fixtureMap[pick.fixtureId],
                  let name = leagueNames[pick.leagueId] else {
                return nil
            }
            return LeagueResult(
                leagueId: pick.leagueId,
                leagueName: name,
                gameweekName: gameweek.name,
                teamName: pick.teamName,
                result: pick.result,
                homeTeamShort: fixture.homeTeamShort,
                awayTeamShort: fixture.awayTeamShort,
                homeScore: fixture.homeScore ?? 0,
                awayScore: fixture.awayScore ?? 0
            )
        }
    }
}
