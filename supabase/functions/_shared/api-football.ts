// API-Football typed client
// All calls must be made server-side (Edge Functions only) — never expose the API key to the iOS client.
// Docs: https://www.api-football.com/documentation-v3
// PL league ID: 39 | Current season: 2025

export const PL_LEAGUE_ID = 39;
export const CURRENT_SEASON = 2025;

// ─── Response types ───────────────────────────────────────────────────────────

export interface ApiFootballResponse<T> {
  get: string;
  parameters: Record<string, string>;
  errors: string[] | Record<string, string>;
  results: number;
  paging: { current: number; total: number };
  response: T[];
}

export interface ApiFixture {
  fixture: {
    id: number;
    referee: string | null;
    timezone: string;
    date: string; // ISO 8601
    timestamp: number;
    periods: { first: number | null; second: number | null };
    venue: { id: number | null; name: string | null; city: string | null };
    status: {
      long: string;
      short: FixtureStatus;
      elapsed: number | null;
    };
  };
  league: {
    id: number;
    name: string;
    country: string;
    season: number;
    round: string; // e.g. "Regular Season - 12"
  };
  teams: {
    home: ApiTeam;
    away: ApiTeam;
  };
  goals: {
    home: number | null;
    away: number | null;
  };
  score: {
    halftime: { home: number | null; away: number | null };
    fulltime: { home: number | null; away: number | null };
    extratime: { home: number | null; away: number | null };
    penalty: { home: number | null; away: number | null };
  };
}

export interface ApiTeam {
  id: number;
  name: string;
  logo: string;
  winner: boolean | null;
}

// All statuses returned by API-Football for a fixture
export type FixtureStatus =
  | "NS"   // Not Started
  | "1H"   // First Half
  | "HT"   // Half Time
  | "2H"   // Second Half
  | "ET"   // Extra Time
  | "BT"   // Break Time (between extra time halves)
  | "P"    // Penalty In Progress
  | "SUSP" // Match Suspended
  | "INT"  // Match Interrupted
  | "FT"   // Full Time
  | "AET"  // After Extra Time
  | "PEN"  // After Penalties
  | "PST"  // Postponed
  | "CANC" // Cancelled
  | "ABD"  // Abandoned
  | "AWD"  // Technical Loss
  | "WO";  // WalkOver

// Statuses that represent a completed, settleable match result
export const SETTLED_STATUSES: FixtureStatus[] = ["FT", "AET", "PEN"];

// Statuses that mean the match is void / to be rescheduled
export const VOID_STATUSES: FixtureStatus[] = ["PST", "CANC", "ABD"];

// Statuses that mean the match is live
export const LIVE_STATUSES: FixtureStatus[] = ["1H", "HT", "2H", "ET", "BT", "P", "SUSP", "INT"];

// Simplified H2H meeting shape returned by the get-head-to-head edge function
export interface H2HMeeting {
  fixtureId: number;
  date: string; // ISO 8601
  venue: string | null;
  homeTeam: { id: number; name: string; logo: string };
  awayTeam: { id: number; name: string; logo: string };
  score: { home: number | null; away: number | null };
  status: FixtureStatus;
}

// ─── Client ───────────────────────────────────────────────────────────────────

export class ApiFootballClient {
  private readonly apiKey: string;
  private readonly baseUrl = "https://v3.football.api-sports.io";

  constructor(apiKey: string) {
    if (!apiKey) throw new Error("API_FOOTBALL_KEY is required");
    this.apiKey = apiKey;
  }

  private async get<T>(path: string, params: Record<string, string | number>): Promise<ApiFootballResponse<T>> {
    const url = new URL(path, this.baseUrl);
    for (const [k, v] of Object.entries(params)) {
      url.searchParams.set(k, String(v));
    }

    const res = await fetch(url.toString(), {
      headers: {
        "x-apisports-key": this.apiKey,
      },
    });

    if (!res.ok) {
      throw new Error(`API-Football error: ${res.status} ${res.statusText}`);
    }

    const data = await res.json() as ApiFootballResponse<T>;

    // API-Football returns errors inside the response body, not as HTTP errors
    const errors = data.errors;
    if (Array.isArray(errors) ? errors.length > 0 : Object.keys(errors).length > 0) {
      throw new Error(`API-Football API error: ${JSON.stringify(errors)}`);
    }

    return data;
  }

  /**
   * Fetch all fixtures for a given league season round.
   * round format: "Regular Season - {n}" e.g. "Regular Season - 12"
   */
  async getFixturesByRound(
    roundNumber: number,
    season = CURRENT_SEASON,
    leagueId = PL_LEAGUE_ID,
  ): Promise<ApiFixture[]> {
    const round = `Regular Season - ${roundNumber}`;
    const data = await this.get<ApiFixture>("/fixtures", {
      league: leagueId,
      season,
      round,
    });
    return data.response;
  }

  /**
   * Fetch a single fixture by its API-Football ID.
   * Use this for polling a specific live match.
   */
  async getFixtureById(fixtureId: number): Promise<ApiFixture | null> {
    const data = await this.get<ApiFixture>("/fixtures", { id: fixtureId });
    return data.response[0] ?? null;
  }

  /**
   * Fetch all live fixtures for a given league.
   * Returns only fixtures currently in progress.
   */
  async getLiveFixtures(leagueId = PL_LEAGUE_ID): Promise<ApiFixture[]> {
    const data = await this.get<ApiFixture>("/fixtures", {
      league: leagueId,
      live: "all",
    });
    return data.response;
  }

  /**
   * Fetch all fixtures for a full season (for initial sync / seeding gameweeks).
   */
  async getAllFixturesBySeason(
    season = CURRENT_SEASON,
    leagueId = PL_LEAGUE_ID,
  ): Promise<ApiFixture[]> {
    const data = await this.get<ApiFixture>("/fixtures", {
      league: leagueId,
      season,
    });
    return data.response;
  }

  /**
   * Fetch head-to-head fixtures between two teams.
   * Endpoint: /fixtures/headtohead?h2h={teamId1}-{teamId2}&last={n}
   */
  async getHeadToHead(
    teamId1: number,
    teamId2: number,
    last = 5,
  ): Promise<ApiFixture[]> {
    const data = await this.get<ApiFixture>("/fixtures/headtohead", {
      h2h: `${teamId1}-${teamId2}`,
      last,
    });
    return data.response;
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Parse round number from API-Football round string.
 * "Regular Season - 12" → 12
 */
export function parseRoundNumber(round: string): number | null {
  const match = round.match(/Regular Season - (\d+)/);
  return match ? parseInt(match[1], 10) : null;
}

/**
 * Extract the short team code from the team name.
 * API-Football doesn't always provide a short code — we derive a 3-letter code.
 * e.g. "Manchester City" → "MCI", "Arsenal" → "ARS"
 */
export function teamShortCode(teamName: string): string {
  const overrides: Record<string, string> = {
    "Arsenal": "ARS",
    "Aston Villa": "AVL",
    "Bournemouth": "BOU",
    "Brentford": "BRE",
    "Brighton": "BHA",
    "Brighton & Hove Albion": "BHA",
    "Chelsea": "CHE",
    "Crystal Palace": "CRY",
    "Everton": "EVE",
    "Fulham": "FUL",
    "Ipswich": "IPS",
    "Ipswich Town": "IPS",
    "Leicester": "LEI",
    "Leicester City": "LEI",
    "Liverpool": "LIV",
    "Manchester City": "MCI",
    "Manchester United": "MUN",
    "Newcastle": "NEW",
    "Newcastle United": "NEW",
    "Nottingham Forest": "NFO",
    "Southampton": "SOU",
    "Tottenham": "TOT",
    "Tottenham Hotspur": "TOT",
    "West Ham": "WHU",
    "West Ham United": "WHU",
    "Wolves": "WOL",
    "Wolverhampton": "WOL",
    "Wolverhampton Wanderers": "WOL",
  };

  return overrides[teamName] ?? teamName.substring(0, 3).toUpperCase();
}

/**
 * Map an ApiFixture to a simplified H2HMeeting shape.
 */
export function toH2HMeeting(fixture: ApiFixture): H2HMeeting {
  return {
    fixtureId: fixture.fixture.id,
    date: fixture.fixture.date,
    venue: fixture.fixture.venue.name,
    homeTeam: {
      id: fixture.teams.home.id,
      name: fixture.teams.home.name,
      logo: fixture.teams.home.logo,
    },
    awayTeam: {
      id: fixture.teams.away.id,
      name: fixture.teams.away.name,
      logo: fixture.teams.away.logo,
    },
    score: {
      home: fixture.goals.home,
      away: fixture.goals.away,
    },
    status: fixture.fixture.status.short,
  };
}
