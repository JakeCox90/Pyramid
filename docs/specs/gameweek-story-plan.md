# Gameweek Story Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Spotify Wrapped-style tap-through story experience for each gameweek, with AI-generated editorial commentary and a scrollable overview recap.

**Architecture:** New `gameweek_stories` and `story_views` Supabase tables + `generate-gameweek-story` Edge Function hooked into the settlement pipeline. iOS gets a new `GameweekStoryView` (full-screen stories UI) and `GameweekOverviewView` (scrollable recap), backed by a `GameweekStoryViewModel` and `GameweekStoryService`.

**Tech Stack:** Supabase (Postgres, Edge Functions/Deno), SwiftUI (MVVM), Anthropic API (Claude) for editorial generation.

**Spec:** `docs/specs/gameweek-story.md`

---

## File Structure

### Backend (Supabase)

| File | Responsibility |
|------|---------------|
| `supabase/migrations/20260323_gameweek_stories.sql` | Create `gameweek_stories` + `story_views` tables, RLS policies, indexes |
| `supabase/functions/generate-gameweek-story/index.ts` | Edge Function: assemble league GW data, call LLM, write story row |
| `supabase/functions/generate-gameweek-story/prompts.ts` | Prompt template + tone config for editorial generation |
| `supabase/functions/generate-gameweek-story/analysis.ts` | Upset detection, wildcard selection, story data assembly |
| `supabase/functions/settle-picks/index.ts` | **Modify:** Add `generate-gameweek-story` call after `detectAndDeclareWinner()` |

### iOS — Models

| File | Responsibility |
|------|---------------|
| `ios/Pyramid/Sources/Models/GameweekStory.swift` | `GameweekStory` model (decoded from `gameweek_stories` table) |
| `ios/Pyramid/Sources/Models/StoryCard.swift` | `StoryCard` enum — card types, visibility logic, variant handling |

### iOS — Service

| File | Responsibility |
|------|---------------|
| `ios/Pyramid/Sources/Services/GameweekStoryService.swift` | Fetch story data + mark viewed |

### iOS — Story View (tap-through)

| File | Responsibility |
|------|---------------|
| `ios/Pyramid/Sources/Features/Story/GameweekStoryView.swift` | Full-screen story container: progress bars, tap zones, card paging |
| `ios/Pyramid/Sources/Features/Story/GameweekStoryViewModel.swift` | Loads data, builds card array, tracks viewed state |
| `ios/Pyramid/Sources/Features/Story/StoryCardView.swift` | Card router — switches on `StoryCard` type, renders correct card |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryTitleCard.swift` | Card 1: GW number, league name, progress dots |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryHeadlineCard.swift` | Card 2: AI headline + narrative body |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryUpsetCard.swift` | Card 3: Biggest upset scoreline + casualties |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryEliminatedCard.swift` | Card 4: Eliminated player list |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryWildcardCard.swift` | Card 5: Wildcard pick of the week |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryYourPickCard.swift` | Card 6: User's pick result reveal |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryStandingCard.swift` | Card 7: Still standing / You Won / League Status |
| `ios/Pyramid/Sources/Features/Story/Cards/StoryMassElimCard.swift` | Conditional: "Everyone Lives" mass elimination card |

### iOS — Overview View (scrollable recap)

| File | Responsibility |
|------|---------------|
| `ios/Pyramid/Sources/Features/Story/GameweekOverviewView.swift` | Scrollable recap: stats bar, upset banner, all picks, progress dots |

### iOS — Integration

| File | Responsibility |
|------|---------------|
| `ios/Pyramid/Sources/Features/Leagues/LeagueDetailView.swift` | **Modify:** Add "GW Recap" entry point to story |

---

## Task 1: Database Migration

**Files:**
- Create: `supabase/migrations/20260323_gameweek_stories.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- Gameweek stories (AI-generated editorial content per league per gameweek)
create table public.gameweek_stories (
  id uuid primary key default gen_random_uuid(),
  league_id uuid not null references public.leagues(id) on delete cascade,
  gameweek int not null,
  headline text,
  body text,
  wildcard_pick_id uuid references public.picks(id),
  upset_fixture_id bigint references public.fixtures(id),
  generated_at timestamptz not null default now(),
  is_mass_elimination boolean not null default false,
  idempotency_key text not null unique
);

alter table public.gameweek_stories enable row level security;

create index gameweek_stories_league_gw_idx
  on public.gameweek_stories(league_id, gameweek);

-- RLS: league members can read stories for their leagues
create policy "League members can view stories"
  on public.gameweek_stories for select
  using (
    exists (
      select 1 from public.league_members lm
      where lm.league_id = gameweek_stories.league_id
        and lm.user_id = auth.uid()
    )
  );

-- RLS: only service role can write
-- (No INSERT/UPDATE/DELETE policies = default deny for anon/authenticated)

-- Story views (tracks whether user has seen the story)
create table public.story_views (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  league_id uuid not null references public.leagues(id) on delete cascade,
  gameweek int not null,
  viewed_at timestamptz not null default now(),
  unique (user_id, league_id, gameweek)
);

alter table public.story_views enable row level security;

create index story_views_user_idx on public.story_views(user_id);

-- RLS: users can read and insert their own rows only
create policy "Users can view own story views"
  on public.story_views for select
  using (auth.uid() = user_id);

create policy "Users can mark stories as viewed"
  on public.story_views for insert
  with check (auth.uid() = user_id);
```

- [ ] **Step 2: Apply migration locally**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid && supabase db push`
Expected: Migration applies successfully, tables created.

- [ ] **Step 3: Verify tables exist**

Run: `supabase db reset --dry-run` or check via Supabase Studio at `localhost:54323`
Expected: `gameweek_stories` and `story_views` tables visible with correct columns and RLS enabled.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260323_gameweek_stories.sql
git commit -m "feat(PYR-xxx): add gameweek_stories and story_views tables"
```

---

## Task 2: Story Analysis Functions (Edge Function — analysis.ts)

**Files:**
- Create: `supabase/functions/generate-gameweek-story/analysis.ts`

- [ ] **Step 1: Write the analysis module**

This module queries the DB for a league's gameweek data and computes the structured story elements (biggest upset, wildcard, elimination list).

```typescript
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
  result: string; // e.g. "Won 3-1 vs Wolves"
}

export interface EliminationInfo {
  userId: string;
  displayName: string;
  teamName: string;
  result: string;
  pickId: string;
  isAutoEliminated: boolean; // missed deadline
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

  // Count eliminations per fixture
  const elimByFixture = new Map<number, number>();
  for (const elim of eliminations) {
    if (elim.isAutoEliminated) continue;
    const pick = picks.find((p) => p.id === elim.pickId);
    if (!pick) continue;
    const fid = pick.fixture_id;
    elimByFixture.set(fid, (elimByFixture.get(fid) ?? 0) + 1);
  }

  if (elimByFixture.size === 0) return null;

  // Pick fixture with most eliminations
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
  // Count picks per team
  const teamCounts = new Map<number, any[]>();
  for (const pick of picks) {
    const list = teamCounts.get(pick.team_id) ?? [];
    list.push(pick);
    teamCounts.set(pick.team_id, list);
  }

  // Find teams picked by exactly 1 player
  const solos = [...teamCounts.entries()].filter(([, list]) => list.length === 1);
  if (solos.length === 0) return null;

  // Prefer the one that survived
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
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/generate-gameweek-story/analysis.ts
git commit -m "feat(PYR-xxx): add story context analysis functions"
```

---

## Task 3: Prompt Template (Edge Function — prompts.ts)

**Files:**
- Create: `supabase/functions/generate-gameweek-story/prompts.ts`

- [ ] **Step 1: Write the prompt module**

```typescript
import { StoryContext } from "./analysis.ts";

export interface StoryOutput {
  headline: string;
  body: string;
}

export function buildPrompt(ctx: StoryContext): string {
  const elimNames = ctx.eliminations.map((e) =>
    e.isAutoEliminated ? `${e.displayName} (missed deadline)` : `${e.displayName} (picked ${e.teamName})`
  ).join(", ");

  const survNames = ctx.survivors.map((s) => `${s.displayName} (${s.teamName}: ${s.result})`).join(", ");

  const upsetLine = ctx.upsetFixture
    ? `Biggest upset: ${ctx.upsetFixture.homeTeam} ${ctx.upsetFixture.homeScore}–${ctx.upsetFixture.awayScore} ${ctx.upsetFixture.awayTeam} (${ctx.upsetFixture.eliminationCount} eliminated).`
    : "No major upsets this week.";

  const massElimLine = ctx.isMassElimination
    ? "MASS ELIMINATION occurred — every remaining player was eliminated, so ALL were reinstated per the rules."
    : "";

  return `You are the narrator of a Premier League Last Man Standing league called "${ctx.leagueName}".

Gameweek ${ctx.gameweek} has just finished. Here's what happened:

Players remaining before this GW: ${ctx.activeBeforeSettlement} of ${ctx.totalMembers}
Eliminated this week: ${ctx.eliminations.length > 0 ? elimNames : "Nobody — everyone survived."}
Survived this week: ${survNames || "Nobody (see mass elimination)."}
${upsetLine}
${massElimLine}

Write a short, punchy recap:
- "headline": a dramatic headline (max 5 words, no quotes)
- "body": a narrative paragraph (max 60 words) referencing specific players and events

Tone: witty, opinionated football banter. Like a group chat narrator who's watched every game. Use first names only. Be specific — never generic.

Respond with valid JSON only: {"headline": "...", "body": "..."}`;
}

export function parseStoryOutput(raw: string): StoryOutput {
  // Strip markdown code fences if present
  const cleaned = raw.replace(/```json?\n?/g, "").replace(/```/g, "").trim();
  const parsed = JSON.parse(cleaned);
  return {
    headline: String(parsed.headline).slice(0, 100),
    body: String(parsed.body).slice(0, 500),
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/generate-gameweek-story/prompts.ts
git commit -m "feat(PYR-xxx): add story prompt template and parser"
```

---

## Task 4: Edge Function — generate-gameweek-story/index.ts

**Files:**
- Create: `supabase/functions/generate-gameweek-story/index.ts`

- [ ] **Step 1: Write the edge function**

```typescript
import { getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { alertSlack } from "../_shared/alert.ts";
import { buildStoryContext } from "./analysis.ts";
import { buildPrompt, parseStoryOutput } from "./prompts.ts";

interface RequestBody {
  leagueId: string;
  gameweek: number;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const log = createLogger("generate-gameweek-story", req);

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const { leagueId, gameweek } = body;
  if (!leagueId || !gameweek) {
    return json({ error: "leagueId and gameweek required" }, 400);
  }

  const idempotencyKey = `${leagueId}_${gameweek}`;
  const db = getServiceClient();

  try {
    // 1. Build story context from settled data
    log.info("Building story context", { leagueId, gameweek });
    const ctx = await buildStoryContext(db, leagueId, gameweek);

    // 2. Generate editorial via LLM
    log.info("Generating editorial", { eliminations: ctx.eliminations.length, survivors: ctx.survivors.length });
    const prompt = buildPrompt(ctx);

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    let headline: string | null = null;
    let storyBody: string | null = null;

    if (anthropicKey) {
      try {
        const llmResponse = await fetch("https://api.anthropic.com/v1/messages", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-api-key": anthropicKey,
            "anthropic-version": "2023-06-01",
          },
          body: JSON.stringify({
            model: "claude-haiku-4-5-20251001",
            max_tokens: 256,
            messages: [{ role: "user", content: prompt }],
          }),
        });

        if (llmResponse.ok) {
          const llmData = await llmResponse.json();
          const rawText = llmData.content?.[0]?.text ?? "";
          const parsed = parseStoryOutput(rawText);
          headline = parsed.headline;
          storyBody = parsed.body;
          log.info("Editorial generated", { headline });
        } else {
          log.warn("LLM API returned non-OK", { status: llmResponse.status });
        }
      } catch (llmErr) {
        log.warn("LLM generation failed, proceeding without editorial", { error: String(llmErr) });
      }
    } else {
      log.warn("ANTHROPIC_API_KEY not set, skipping editorial generation");
    }

    // 3. Write story row (idempotent)
    const { error: insertError } = await db.from("gameweek_stories").insert({
      league_id: leagueId,
      gameweek,
      headline,
      body: storyBody,
      wildcard_pick_id: ctx.wildcardPick?.pickId ?? null,
      upset_fixture_id: ctx.upsetFixture?.fixtureId ?? null,
      is_mass_elimination: ctx.isMassElimination,
      idempotency_key: idempotencyKey,
    });

    if (insertError) {
      if (insertError.code === "23505") {
        log.info("Story already exists (idempotent no-op)", { idempotencyKey });
        return json({ status: "already_exists" }, 200);
      }
      throw insertError;
    }

    log.complete("ok", { leagueId, gameweek, hasEditorial: !!headline });
    return json({ status: "created", headline, hasEditorial: !!headline }, 201);
  } catch (err) {
    log.error("Story generation failed", err, { leagueId, gameweek });
    await alertSlack("generate-gameweek-story failed", {
      leagueId,
      gameweek,
      error: err instanceof Error ? err.message : String(err),
    });
    return json({ error: "Internal server error" }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/generate-gameweek-story/
git commit -m "feat(PYR-xxx): add generate-gameweek-story edge function"
```

---

## Task 5: Hook into Settlement Pipeline

**Files:**
- Modify: `supabase/functions/settle-picks/index.ts` — after `detectAndDeclareWinner()` call

- [ ] **Step 1: Read the current settle-picks code**

Read `supabase/functions/settle-picks/index.ts` and find the block where `detectAndDeclareWinner()` is called — this is inside the `isGameweekFullySettled()` check. The story generation call goes immediately after winner detection.

- [ ] **Step 2: Add story generation call gated on `isGameweekFullySettled()`**

**IMPORTANT:** The story must only generate once ALL fixtures in the gameweek are settled, not after each individual fixture. The `settle-picks` handler runs per-fixture, so the story call must be gated on the full-settlement check.

Find the block inside `detectAndDeclareWinner()` where `isGameweekFullySettled()` is called (around line 245 of `settle-picks/index.ts`). The story generation should fire **inside that `if` block** — after the settlement check passes, alongside (not after) the winner detection logic. This ensures it only fires once per league per gameweek.

Add this immediately after the `isGameweekFullySettled()` check passes, before the winner detection branches:

```typescript
// Generate gameweek story (non-blocking, fire-and-forget)
// Fires only when ALL GW fixtures are settled for this league
try {
  const storyResponse = await fetch(
    `${Deno.env.get("SUPABASE_URL")}/functions/v1/generate-gameweek-story`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
      },
      body: JSON.stringify({ leagueId, gameweek: gameweekId }),
    },
  );
  log.info("Story generation triggered", {
    leagueId,
    gameweek: gameweekId,
    status: storyResponse.status,
  });
} catch (storyErr) {
  // Non-blocking: log and continue, settlement is already complete
  log.warn("Story generation call failed", {
    leagueId,
    gameweek: gameweekId,
    error: storyErr instanceof Error ? storyErr.message : String(storyErr),
  });
}
```

If `isGameweekFullySettled()` is not easily accessible outside `detectAndDeclareWinner()`, extract the full-settlement check into a separate guard at the caller level, or add the story trigger inside `detectAndDeclareWinner()` before the winner-detection branches.

- [ ] **Step 3: Verify settle-picks still works**

Run: `deno check supabase/functions/settle-picks/index.ts`
Expected: No type errors.

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/settle-picks/index.ts
git commit -m "feat(PYR-xxx): hook story generation into settlement pipeline"
```

---

## Task 6: iOS Models — GameweekStory + StoryCard

**Files:**
- Create: `ios/Pyramid/Sources/Models/GameweekStory.swift`
- Create: `ios/Pyramid/Sources/Models/StoryCard.swift`

- [ ] **Step 1: Write the GameweekStory model**

```swift
import Foundation

struct GameweekStory: Codable, Sendable, Equatable {
    let id: String
    let leagueId: String
    let gameweek: Int
    let headline: String?
    let body: String?
    let wildcardPickId: String?
    let upsetFixtureId: Int?
    let isMassElimination: Bool
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case gameweek
        case headline
        case body
        case wildcardPickId = "wildcard_pick_id"
        case upsetFixtureId = "upset_fixture_id"
        case isMassElimination = "is_mass_elimination"
        case generatedAt = "generated_at"
    }
}
```

- [ ] **Step 2: Write the StoryCard model**

```swift
import Foundation

enum StoryCard: Identifiable {
    case title(leagueName: String, gameweek: Int, aliveCount: Int, totalCount: Int)
    case headline(headline: String, body: String)
    case upset(fixture: Fixture, eliminationCount: Int)
    case eliminated(players: [EliminatedPlayer])
    case massElimination(playerCount: Int)
    case wildcard(player: WildcardPlayer)
    case yourPick(pick: YourPickResult)
    case standing(players: [StandingPlayer], totalCount: Int, userStatus: UserStoryStatus)

    var id: String {
        switch self {
        case .title: return "title"
        case .headline: return "headline"
        case .upset: return "upset"
        case .eliminated: return "eliminated"
        case .massElimination: return "mass-elim"
        case .wildcard: return "wildcard"
        case .yourPick: return "your-pick"
        case .standing: return "standing"
        }
    }
}

enum UserStoryStatus {
    case survived
    case eliminated
    case winner
    case missedDeadline
    case voidSurvived
}

struct EliminatedPlayer: Identifiable, Equatable {
    let id: String // userId
    let displayName: String
    let teamName: String
    let result: String
    let isAutoEliminated: Bool
}

struct WildcardPlayer: Equatable {
    let displayName: String
    let teamName: String
    let result: String
    let survived: Bool
}

struct YourPickResult: Equatable {
    let teamName: String?
    let teamId: Int?
    let result: String?
    let status: UserStoryStatus
}

struct StandingPlayer: Identifiable, Equatable {
    let id: String // userId
    let displayName: String
    let isCurrentUser: Bool
}
```

- [ ] **Step 3: Run xcodegen**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`
Expected: Project regenerated with new files included.

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Models/GameweekStory.swift ios/Pyramid/Sources/Models/StoryCard.swift
git commit -m "feat(PYR-xxx): add GameweekStory and StoryCard models"
```

---

## Task 7: iOS Service — GameweekStoryService

**Files:**
- Create: `ios/Pyramid/Sources/Services/GameweekStoryService.swift`

- [ ] **Step 1: Write the service**

```swift
import Foundation
import Supabase

protocol GameweekStoryServiceProtocol: Sendable {
    func fetchStory(leagueId: String, gameweek: Int) async throws -> GameweekStory?
    func fetchUpsetFixture(fixtureId: Int) async throws -> Fixture?
    func fetchWildcardPick(pickId: String) async throws -> Pick?
    func fetchStoryViewed(leagueId: String, gameweek: Int) async throws -> Bool
    func markStoryViewed(leagueId: String, gameweek: Int) async throws
}

final class GameweekStoryService: GameweekStoryServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchStory(leagueId: String, gameweek: Int) async throws -> GameweekStory? {
        let stories: [GameweekStory] = try await client
            .from("gameweek_stories")
            .select("*")
            .eq("league_id", value: leagueId)
            .eq("gameweek", value: gameweek)
            .limit(1)
            .execute()
            .value
        return stories.first
    }

    func fetchUpsetFixture(fixtureId: Int) async throws -> Fixture? {
        let fixtures: [Fixture] = try await client
            .from("fixtures")
            .select("*")
            .eq("id", value: fixtureId)
            .limit(1)
            .execute()
            .value
        return fixtures.first
    }

    func fetchWildcardPick(pickId: String) async throws -> Pick? {
        let picks: [Pick] = try await client
            .from("picks")
            .select("*")
            .eq("id", value: pickId)
            .limit(1)
            .execute()
            .value
        return picks.first
    }

    func fetchStoryViewed(leagueId: String, gameweek: Int) async throws -> Bool {
        let userId = try await client.auth.session.user.id.uuidString
        let views: [StoryViewRow] = try await client
            .from("story_views")
            .select("id")
            .eq("user_id", value: userId)
            .eq("league_id", value: leagueId)
            .eq("gameweek", value: gameweek)
            .limit(1)
            .execute()
            .value
        return !views.isEmpty
    }

    func markStoryViewed(leagueId: String, gameweek: Int) async throws {
        let userId = try await client.auth.session.user.id.uuidString
        try await client
            .from("story_views")
            .upsert(
                StoryViewInsert(userId: userId, leagueId: leagueId, gameweek: gameweek),
                onConflict: "user_id,league_id,gameweek"
            )
            .execute()
    }
}

private struct StoryViewRow: Decodable {
    let id: String
}

private struct StoryViewInsert: Encodable {
    let userId: String
    let leagueId: String
    let gameweek: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case leagueId = "league_id"
        case gameweek
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Services/GameweekStoryService.swift
git commit -m "feat(PYR-xxx): add GameweekStoryService"
```

---

## Task 8: iOS ViewModel — GameweekStoryViewModel

**Files:**
- Create: `ios/Pyramid/Sources/Features/Story/GameweekStoryViewModel.swift`

- [ ] **Step 1: Write the ViewModel**

```swift
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
            async let storyFetch = storyService.fetchStory(leagueId: leagueId, gameweek: gameweek)
            async let membersFetch = standingsService.fetchMembers(leagueId: leagueId)
            async let picksFetch = standingsService.fetchLockedPicks(leagueId: leagueId, gameweekId: gameweek)
            async let viewedFetch = storyService.fetchStoryViewed(leagueId: leagueId, gameweek: gameweek)

            let story = try await storyFetch
            let members = try await membersFetch
            let picks = try await picksFetch
            hasBeenViewed = try await viewedFetch

            // Fetch upset fixture if story references one
            var upsetFixture: Fixture?
            if let upsetId = story?.upsetFixtureId {
                upsetFixture = try? await storyService.fetchUpsetFixture(fixtureId: upsetId)
            }

            // Fetch wildcard pick if story references one
            var wildcardPick: Pick?
            if let wcId = story?.wildcardPickId {
                wildcardPick = try? await storyService.fetchWildcardPick(pickId: wcId)
            }

            cards = buildCards(
                story: story, members: members, picks: picks,
                upsetFixture: upsetFixture, wildcardPick: wildcardPick
            )
        } catch {
            errorMessage = AppError.from(error).userMessage
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
        try? await storyService.markStoryViewed(leagueId: leagueId, gameweek: gameweek)
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
        let eliminatedThisWeek = members.filter { $0.eliminatedInGameweekId == gameweek && $0.status == .eliminated }
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

        // 4b. Mass elimination card (if mass elim occurred)
        if isMassElim {
            result.append(.massElimination(playerCount: eliminatedThisWeek.count))
        }

        // 5. Wildcard (if wildcard pick was fetched)
        if let wcPick = wildcardPick {
            let wcMember = members.first { $0.userId == wcPick.userId }
            result.append(.wildcard(player: WildcardPlayer(
                displayName: wcMember?.profiles.displayLabel ?? "Unknown",
                teamName: wcPick.teamName,
                result: "\(wcPick.teamName)",
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
```

- [ ] **Step 2: Run xcodegen**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Story/GameweekStoryViewModel.swift
git commit -m "feat(PYR-xxx): add GameweekStoryViewModel with card assembly"
```

---

## Task 9: iOS Story View — Container + Navigation

**Files:**
- Create: `ios/Pyramid/Sources/Features/Story/GameweekStoryView.swift`
- Create: `ios/Pyramid/Sources/Features/Story/StoryCardView.swift`

- [ ] **Step 1: Write GameweekStoryView**

The main container: progress bars at top, tap zones for navigation, renders current card.

```swift
import SwiftUI

struct GameweekStoryView: View {
    @StateObject private var viewModel: GameweekStoryViewModel
    @Environment(\.dismiss) private var dismiss

    init(leagueId: String, gameweek: Int, leagueName: String) {
        _viewModel = StateObject(wrappedValue: GameweekStoryViewModel(
            leagueId: leagueId,
            gameweek: gameweek,
            leagueName: leagueName
        ))
    }

    var body: some View {
        ZStack {
            Theme.Color.Surface.Background.page.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Status.Error.resting)
            } else {
                storyContent
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.load()
            await viewModel.markViewed()
        }
        .fullScreenCover(isPresented: $viewModel.showOverview) {
            GameweekOverviewView(viewModel: viewModel)
        }
    }

    private var storyContent: some View {
        ZStack {
            // Current card
            ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                StoryCardView(card: card)
                    .opacity(index == viewModel.currentIndex ? 1 : 0)
                    .scaleEffect(index == viewModel.currentIndex ? 1 : 0.97)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.currentIndex)
            }

            // Progress bars
            VStack {
                progressBars
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                Spacer()

                // View Recap button on last card
                if viewModel.currentIndex == viewModel.totalCards - 1 {
                    Button {
                        viewModel.showOverview = true
                    } label: {
                        Text("View Full Recap")
                            .font(Theme.Typography.label01)
                            .foregroundStyle(Theme.Color.Primary.text)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Theme.Color.Primary.resting)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 48)
                }
            }

            // Tap zones (use GeometryReader, not UIScreen.main)
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.goBack() }
                        .frame(width: geo.size.width * 0.3)

                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .onTapGesture { viewModel.advance() }
                }
            }
        }
    }

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.totalCards, id: \.self) { index in
                Capsule()
                    .fill(index <= viewModel.currentIndex
                        ? Color(hex: "#FFC758")
                        : Color.white.opacity(0.15))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
            }
        }
        .accessibilityLabel("Card \(viewModel.currentIndex + 1) of \(viewModel.totalCards)")
    }
}
```

- [ ] **Step 2: Write StoryCardView (router)**

```swift
import SwiftUI

struct StoryCardView: View {
    let card: StoryCard

    var body: some View {
        switch card {
        case let .title(leagueName, gameweek, aliveCount, totalCount):
            StoryTitleCard(leagueName: leagueName, gameweek: gameweek,
                          aliveCount: aliveCount, totalCount: totalCount)
        case let .headline(headline, body):
            StoryHeadlineCard(headline: headline, body: body)
        case let .upset(fixture, eliminationCount):
            StoryUpsetCard(fixture: fixture, eliminationCount: eliminationCount)
        case let .eliminated(players):
            StoryEliminatedCard(players: players)
        case let .massElimination(playerCount):
            StoryMassElimCard(playerCount: playerCount)
        case let .wildcard(player):
            StoryWildcardCard(player: player)
        case let .yourPick(pick):
            StoryYourPickCard(pick: pick)
        case let .standing(players, totalCount, userStatus):
            StoryStandingCard(players: players, totalCount: totalCount, userStatus: userStatus)
        }
    }
}
```

- [ ] **Step 3: Run xcodegen**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Features/Story/GameweekStoryView.swift \
        ios/Pyramid/Sources/Features/Story/StoryCardView.swift
git commit -m "feat(PYR-xxx): add story container view with tap navigation"
```

---

## Task 10: iOS Story Cards — Individual Card Views

**Files:**
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryTitleCard.swift`
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryHeadlineCard.swift`
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryUpsetCard.swift`
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryEliminatedCard.swift`
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryWildcardCard.swift`
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryYourPickCard.swift`
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryStandingCard.swift`
- Create: `ios/Pyramid/Sources/Features/Story/Cards/StoryMassElimCard.swift`

- [ ] **Step 1: Create placeholder card views**

Each card view should be a simple structural placeholder. **Final designs will come from Figma** — these are scaffolds with the correct data bindings. Each card uses the brand gradient background and renders its data using brand typography tokens.

The implementer should create each file following the same pattern:

```swift
import SwiftUI

struct StoryTitleCard: View {
    let leagueName: String
    let gameweek: Int
    let aliveCount: Int
    let totalCount: Int

    var body: some View {
        ZStack {
            Theme.Gradient.primary.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.s60) {
                Text("Gameweek \(gameweek)")
                    .font(Theme.Typography.overline)
                    .foregroundStyle(Color(hex: "#FFC758"))

                Text(leagueName)
                    .font(Theme.Typography.h1)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                    .multilineTextAlignment(.center)

                HStack(spacing: Theme.Spacing.s20) {
                    Text("\(aliveCount)")
                        .font(Theme.Typography.h2)
                        .foregroundStyle(Theme.Color.Status.Success.resting)
                    Text("of \(totalCount) remaining")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }
            }
            .padding(Theme.Spacing.s70)
        }
    }
}
```

Repeat this pattern for each card type, binding the correct data properties. Each card should:
- Use the brand gradient as background (check if `Theme.Gradient.primary` exists; if not, use `LinearGradient(colors: [Color(hex: "#5E4E80"), Color(hex: "#2C253D")], startPoint: .topTrailing, endPoint: .bottomLeading)`)
- Use brand typography tokens (`Theme.Typography.*`)
- Use brand color tokens (`Theme.Color.*`)
- Accept its data via init parameters (matching the `StoryCard` enum cases)
- Include `.accessibilityLabel` on the root view describing the card content (e.g. "Gameweek 12, The Lads FC, 8 of 20 players remaining")
- Support `.accessibilityAction(.default)` for VoiceOver navigation (advance to next card)

- [ ] **Step 2: Create all 8 card files following the pattern above**

- [ ] **Step 3: Run xcodegen**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Features/Story/Cards/
git commit -m "feat(PYR-xxx): add placeholder story card views"
```

---

## Task 11: iOS Overview View — Scrollable Recap

**Files:**
- Create: `ios/Pyramid/Sources/Features/Story/GameweekOverviewView.swift`

- [ ] **Step 1: Write the overview view**

Scrollable recap screen with stats bar, upset banner, all picks listed. Uses the same ViewModel data as the story cards.

```swift
import SwiftUI

struct GameweekOverviewView: View {
    @ObservedObject var viewModel: GameweekStoryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
                    headerSection
                    statsSection
                    // Upset banner, survived list, eliminated list
                    // Built from viewModel.cards data
                }
                .padding(Theme.Spacing.s60)
            }
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("GW\(viewModel.gameweek) Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Replay Story") {
                        dismiss()
                        // Parent view should re-present GameweekStoryView
                    }
                    .font(Theme.Typography.label01)
                    .foregroundStyle(Color(hex: "#FFC758"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.Typography.label01)
                        .foregroundStyle(Theme.Color.Primary.resting)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Gameweek \(viewModel.gameweek)")
                .font(Theme.Typography.overline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            Text(viewModel.leagueName)
                .font(Theme.Typography.h2)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
    }

    private var statsSection: some View {
        // Implementer: derive survived/eliminated/already-out counts from viewModel data
        // Use stat boxes matching the wireframe pattern
        EmptyView()
    }
}
```

- [ ] **Step 2: Run xcodegen**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Story/GameweekOverviewView.swift
git commit -m "feat(PYR-xxx): add gameweek overview recap view"
```

---

## Task 12: iOS Integration — League Detail Entry Point

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Leagues/LeagueDetailView.swift`

- [ ] **Step 1: Read the current LeagueDetailView**

Read the file to understand the current layout and find where to add the "GW Recap" button.

- [ ] **Step 2: Add story entry point**

Add a button/row to the league detail screen that opens the story. Use `.fullScreenCover` to present it:

```swift
// Add @State
@State private var showStory = false

// Add button in the view body (near the top, after league header)
Button {
    showStory = true
} label: {
    HStack {
        Image(systemName: "play.circle.fill")
        Text("GW\(gameweek) Recap")
            .font(Theme.Typography.label01)
    }
    .foregroundStyle(Color(hex: "#FFC758"))
    .padding(.horizontal, Theme.Spacing.s40)
    .padding(.vertical, Theme.Spacing.s20)
    .background(Color(hex: "#FFC758").opacity(0.1))
    .clipShape(Capsule())
}
.fullScreenCover(isPresented: $showStory) {
    GameweekStoryView(
        leagueId: league.id,
        gameweek: currentGameweek,
        leagueName: league.name
    )
}
```

- [ ] **Step 3: Build and verify**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`
Verify: The button appears in league detail and tapping it opens the story view.

- [ ] **Step 4: Commit**

```bash
git add ios/Pyramid/Sources/Features/Leagues/LeagueDetailView.swift
git commit -m "feat(PYR-xxx): add GW Recap entry point to league detail"
```

---

## Task 13: Final Wiring + XcodeGen

- [ ] **Step 1: Run xcodegen to ensure all new files are included**

Run: `cd /Users/jakecox/Documents/GitHub/Pyramid/ios && xcodegen generate`

- [ ] **Step 2: Build the project**

Run: `xcodebuild -project ios/Pyramid.xcodeproj -scheme Pyramid -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Fix any build errors**

Address any missing imports, type mismatches, or compilation issues.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(PYR-xxx): wire up gameweek story feature end-to-end"
```

---

## Dependency Order

```
Backend chain:  Task 1 (migration) → Task 2 (analysis) → Task 3 (prompts) → Task 4 (edge function) → Task 5 (settlement hook)
iOS chain:      Task 1 (migration) → Task 6 (models) → Task 7 (service) → Task 8 (viewmodel) → Task 9 (story view) → Task 10 (cards) → Task 11 (overview) → Task 12 (integration)
Final:          Both chains → Task 13 (wiring)
```

The backend chain (Tasks 2-5) and iOS chain (Tasks 6-12) are independent and **can run in parallel** — they only share a dependency on Task 1 (migration). Task 13 depends on everything.
