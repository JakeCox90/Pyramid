import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export interface StoryContext {
  leagueId: string;
  leagueName: string;
  gameweek: number;
  totalMembers: number;
  activeBeforeSettlement: number;
  survivors: SurvivorInfo[];
  eliminations: EliminationInfo[];
  isMassElimination: boolean;
  upsetFixture: UpsetFixture | null;
  wildcardPick: WildcardPick | null;
}

export interface SurvivorInfo {
  userId: string;
  displayName: string;
  teamName: string;
  result: string;
}

export interface EliminationInfo {
  userId: string;
  displayName: string;
  teamName: string;
  result: string;
  pickId: string;
  isAutoEliminated: boolean;
}

export interface UpsetFixture {
  fixtureId: number;
  homeTeam: string;
  awayTeam: string;
  homeScore: number;
  awayScore: number;
  eliminationCount: number;
}

export interface WildcardPick {
  pickId: string;
  userId: string;
  displayName: string;
  teamName: string;
  result: string;
  survived: boolean;
}

export async function buildStoryContext(
  db: SupabaseClient,
  leagueId: string,
  gameweek: number,
): Promise<StoryContext> {
  // 1. Fetch league name
  const { data: league } = await db
    .from("leagues")
    .select("name")
    .eq("id", leagueId)
    .single();

  // 2. Fetch all members with profiles
  const { data: members } = await db
    .from("league_members")
    .select("id, user_id, status, eliminated_in_gameweek_id, profiles(display_name, username)")
    .eq("league_id", leagueId);

  // 3. Fetch all locked picks for this GW with fixture data
  const { data: picks } = await db
    .from("picks")
    .select(`
      id, user_id, team_name, team_id, result, fixture_id,
      fixtures(id, home_team_name, home_team_short, away_team_name, away_team_short,
               home_score, away_score, status)
    `)
    .eq("league_id", leagueId)
    .eq("gameweek_id", gameweek)
    .eq("is_locked", true);

  // 4. Check settlement log for mass elimination
  const { data: settlementLogs } = await db
    .from("settlement_log")
    .select("is_mass_elimination")
    .eq("league_id", leagueId)
    .eq("gameweek_id", gameweek);

  const isMassElimination = settlementLogs?.some((l) => l.is_mass_elimination) ?? false;

  // 5. Build survivors and eliminations
  const totalMembers = members?.length ?? 0;
  const survivors: SurvivorInfo[] = [];
  const eliminations: EliminationInfo[] = [];

  for (const pick of picks ?? []) {
    const member = members?.find((m) => m.user_id === pick.user_id);
    const profile = member?.profiles;
    const displayName = profile?.display_name ?? profile?.username ?? "Unknown";
    const fixture = pick.fixtures;
    const resultStr = formatResult(pick.team_name, fixture);

    if (pick.result === "survived") {
      survivors.push({ userId: pick.user_id, displayName, teamName: pick.team_name, result: resultStr });
    } else if (pick.result === "eliminated") {
      eliminations.push({
        userId: pick.user_id, displayName, teamName: pick.team_name,
        result: resultStr, pickId: pick.id, isAutoEliminated: false,
      });
    }
  }

  // 6. Find auto-eliminated members (no pick this GW)
  const pickedUserIds = new Set((picks ?? []).map((p) => p.user_id));
  for (const member of members ?? []) {
    if (
      member.eliminated_in_gameweek_id === gameweek &&
      !pickedUserIds.has(member.user_id)
    ) {
      const profile = member.profiles;
      const displayName = profile?.display_name ?? profile?.username ?? "Unknown";
      eliminations.push({
        userId: member.user_id, displayName, teamName: "—",
        result: "Missed deadline", pickId: "", isAutoEliminated: true,
      });
    }
  }

  // 7. Find biggest upset (fixture that caused most eliminations in this league)
  const upsetFixture = findBiggestUpset(picks ?? [], eliminations);

  // 8. Find wildcard pick (fewest players picked that team, min 1)
  const wildcardPick = findWildcard(picks ?? [], members ?? []);

  const activeBeforeSettlement = totalMembers - members!.filter(
    (m) => m.status === "eliminated" && m.eliminated_in_gameweek_id !== gameweek
  ).length;

  return {
    leagueId,
    leagueName: league?.name ?? "Unknown League",
    gameweek,
    totalMembers,
    activeBeforeSettlement,
    survivors,
    eliminations,
    isMassElimination,
    upsetFixture,
    wildcardPick,
  };
}

function findBiggestUpset(picks: any[], eliminations: EliminationInfo[]): UpsetFixture | null {
  if (eliminations.length === 0) return null;

  const elimByFixture = new Map<number, number>();
  for (const elim of eliminations) {
    if (elim.isAutoEliminated) continue;
    const pick = picks.find((p) => p.id === elim.pickId);
    if (!pick) continue;
    const fid = pick.fixture_id;
    elimByFixture.set(fid, (elimByFixture.get(fid) ?? 0) + 1);
  }

  if (elimByFixture.size === 0) return null;

  let maxFid = 0;
  let maxCount = 0;
  for (const [fid, count] of elimByFixture) {
    if (count > maxCount) { maxFid = fid; maxCount = count; }
  }

  const fixturePick = picks.find((p) => p.fixture_id === maxFid);
  const f = fixturePick?.fixtures;
  if (!f) return null;

  return {
    fixtureId: maxFid,
    homeTeam: f.home_team_name,
    awayTeam: f.away_team_name,
    homeScore: f.home_score ?? 0,
    awayScore: f.away_score ?? 0,
    eliminationCount: maxCount,
  };
}

function findWildcard(picks: any[], members: any[]): WildcardPick | null {
  const teamCounts = new Map<number, any[]>();
  for (const pick of picks) {
    const list = teamCounts.get(pick.team_id) ?? [];
    list.push(pick);
    teamCounts.set(pick.team_id, list);
  }

  const solos = [...teamCounts.entries()].filter(([, list]) => list.length === 1);
  if (solos.length === 0) return null;

  const survivedSolo = solos.find(([, list]) => list[0].result === "survived");
  const chosen = survivedSolo ? survivedSolo[1][0] : solos[0][1][0];

  const member = members.find((m: any) => m.user_id === chosen.user_id);
  const profile = member?.profiles;
  const displayName = profile?.display_name ?? profile?.username ?? "Unknown";
  const fixture = chosen.fixtures;

  return {
    pickId: chosen.id,
    userId: chosen.user_id,
    displayName,
    teamName: chosen.team_name,
    result: formatResult(chosen.team_name, fixture),
    survived: chosen.result === "survived",
  };
}

function formatResult(teamName: string, fixture: any): string {
  if (!fixture || fixture.home_score === null) return "Result pending";
  const isHome = fixture.home_team_name === teamName;
  const teamScore = isHome ? fixture.home_score : fixture.away_score;
  const oppScore = isHome ? fixture.away_score : fixture.home_score;
  const oppName = isHome ? fixture.away_team_short : fixture.home_team_short;
  const prefix = teamScore > oppScore ? "Won" : teamScore < oppScore ? "Lost" : "Drew";
  return `${prefix} ${teamScore}–${oppScore} vs ${oppName}`;
}
