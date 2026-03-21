# PYR-107: Achievement Badges System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an achievement badges system where users unlock badges for milestones (first win, 5-GW streak, survived a full round, etc.), displayed on the profile screen, with definitions in config and unlock state in the database.

**Architecture:** Badge definitions live in a static Swift config (iOS) and a matching TypeScript config (Edge Functions). The DB stores only unlock state (`user_achievements` table). Settlement triggers badge evaluation via a new `check-achievements` Edge Function called fire-and-forget from `settle-picks`. The profile screen gets a new badges section that fetches unlocked achievements and renders them against the static badge catalog.

**Tech Stack:** SwiftUI, Supabase (Postgres + Edge Functions), Deno/TypeScript

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `supabase/migrations/20260321000000_user_achievements.sql` | Create | DB table + RLS + index |
| `supabase/functions/check-achievements/index.ts` | Create | Evaluate badge conditions, insert unlocks |
| `supabase/functions/check-achievements/badges.ts` | Create | Badge definitions + condition checkers |
| `supabase/functions/settle-picks/index.ts` | Modify | Fire-and-forget call to check-achievements |
| `supabase/config.toml` | Modify | Add `[functions.check-achievements]` |
| `ios/Pyramid/Sources/Models/Achievement.swift` | Create | Badge model + static catalog |
| `ios/Pyramid/Sources/Services/AchievementService.swift` | Create | Fetch unlocked badges from Supabase |
| `ios/Pyramid/Sources/Features/Profile/AchievementsView.swift` | Create | Badge grid UI component |
| `ios/Pyramid/Sources/Features/Profile/ProfileView.swift` | Modify | Add achievements section |
| `ios/Pyramid/Sources/Features/Profile/ProfileViewModel.swift` | Modify | Load achievements |
| `supabase/functions/check-achievements/badges.test.ts` | Create | Backend badge evaluation tests |
| `ios/PyramidTests/AchievementTests.swift` | Create | Badge catalog + unlock logic tests |

---

## Badge Catalog (v1)

| ID | Name | Description | SF Symbol | Condition |
|----|------|-------------|-----------|-----------|
| `first_win` | Champion | Win your first league | `trophy.fill` | `wins >= 1` |
| `streak_5` | On Fire | Survive 5 gameweeks in a row | `flame.fill` | `longestSurvivalStreak >= 5` |
| `streak_10` | Untouchable | Survive 10 gameweeks in a row | `bolt.shield.fill` | `longestSurvivalStreak >= 10` |
| `first_pick` | Rookie | Make your first pick | `hand.point.up.fill` | `totalPicksMade >= 1` |
| `picks_50` | Veteran | Make 50 picks | `star.fill` | `totalPicksMade >= 50` |
| `joined_5` | Social Butterfly | Join 5 leagues | `person.3.fill` | `totalLeaguesJoined >= 5` |
| `mass_elim_survivor` | Unkillable | Survive a mass elimination round | `arrow.counterclockwise` | Custom: pick result changed from eliminated→survived in same GW |
| `full_round` | Perfect Round | Survive every match in a gameweek | `checkmark.seal.fill` | All GW picks survived (no voids) |

---

## Task Breakdown

### Task 1: Database Migration — `user_achievements` Table

**Files:**
- Create: `supabase/migrations/20260321000000_user_achievements.sql`

- [ ] **Step 1: Write the migration**

```sql
-- Migration: 20260321000000_user_achievements
-- Description: Achievement badges — stores unlock state per user
-- ROLLBACK: drop table public.user_achievements;

create table public.user_achievements (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  badge_id    text not null,
  unlocked_at timestamptz not null default now(),
  context     jsonb,  -- optional metadata (e.g. which league triggered it)

  unique (user_id, badge_id)
);

comment on table public.user_achievements is 'Tracks which achievement badges each user has unlocked.';

create index user_achievements_user_idx on public.user_achievements (user_id);

alter table public.user_achievements enable row level security;

-- Badges are publicly readable (visible on other users' profiles)
create policy "Achievements are publicly readable"
  on public.user_achievements for select
  using (true);

-- Service role inserts only — no client inserts
-- Service role bypasses RLS, so with check (false) blocks client inserts
-- while allowing Edge Functions to insert via service role key
create policy "No client inserts"
  on public.user_achievements for insert
  with check (false);
```

- [ ] **Step 2: Verify migration syntax**

Run: `cd /home/user/Pyramid && cat supabase/migrations/20260321000000_user_achievements.sql`
Verify: SQL is valid, follows naming conventions from existing migrations.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260321000000_user_achievements.sql
git commit -m "feat(PYR-107): add user_achievements table migration"
```

---

### Task 2: Badge Definitions — Backend (TypeScript)

**Files:**
- Create: `supabase/functions/check-achievements/badges.ts`

- [ ] **Step 1: Write badge definitions and condition types**

```typescript
// Badge definitions and condition evaluation for the achievements system.
// Badge IDs here must match the iOS Achievement.swift catalog exactly.

export interface BadgeDefinition {
  id: string;
  name: string;
  description: string;
  condition: BadgeCondition;
}

export type BadgeCondition =
  | { type: "stat_threshold"; stat: string; threshold: number }
  | { type: "custom"; key: string };

export interface UserStats {
  wins: number;
  totalPicksMade: number;
  longestSurvivalStreak: number;
  totalLeaguesJoined: number;
}

export const BADGE_CATALOG: BadgeDefinition[] = [
  {
    id: "first_win",
    name: "Champion",
    description: "Win your first league",
    condition: { type: "stat_threshold", stat: "wins", threshold: 1 },
  },
  {
    id: "streak_5",
    name: "On Fire",
    description: "Survive 5 gameweeks in a row",
    condition: { type: "stat_threshold", stat: "longestSurvivalStreak", threshold: 5 },
  },
  {
    id: "streak_10",
    name: "Untouchable",
    description: "Survive 10 gameweeks in a row",
    condition: { type: "stat_threshold", stat: "longestSurvivalStreak", threshold: 10 },
  },
  {
    id: "first_pick",
    name: "Rookie",
    description: "Make your first pick",
    condition: { type: "stat_threshold", stat: "totalPicksMade", threshold: 1 },
  },
  {
    id: "picks_50",
    name: "Veteran",
    description: "Make 50 picks",
    condition: { type: "stat_threshold", stat: "totalPicksMade", threshold: 50 },
  },
  {
    id: "joined_5",
    name: "Social Butterfly",
    description: "Join 5 leagues",
    condition: { type: "stat_threshold", stat: "totalLeaguesJoined", threshold: 5 },
  },
  {
    id: "mass_elim_survivor",
    name: "Unkillable",
    description: "Survive a mass elimination round",
    condition: { type: "custom", key: "mass_elim_survivor" },
  },
  {
    id: "full_round",
    name: "Perfect Round",
    description: "Survive every match in a gameweek",
    condition: { type: "custom", key: "full_round" },
  },
];

export function evaluateStatBadges(
  stats: UserStats,
  alreadyUnlocked: Set<string>,
): string[] {
  const newBadges: string[] = [];

  for (const badge of BADGE_CATALOG) {
    if (alreadyUnlocked.has(badge.id)) continue;
    if (badge.condition.type !== "stat_threshold") continue;

    const value = stats[badge.condition.stat as keyof UserStats];
    if (typeof value === "number" && value >= badge.condition.threshold) {
      newBadges.push(badge.id);
    }
  }

  return newBadges;
}
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/check-achievements/badges.ts
git commit -m "feat(PYR-107): add badge catalog and stat evaluation logic"
```

---

### Task 2b: Backend Badge Evaluation Tests

**Files:**
- Create: `supabase/functions/check-achievements/badges.test.ts`

- [ ] **Step 1: Write tests for evaluateStatBadges**

```typescript
import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { evaluateStatBadges } from "./badges.ts";
import type { UserStats } from "./badges.ts";

Deno.test("evaluateStatBadges: returns empty when no thresholds met", () => {
  const stats: UserStats = { wins: 0, totalPicksMade: 0, longestSurvivalStreak: 0, totalLeaguesJoined: 0 };
  const result = evaluateStatBadges(stats, new Set());
  assertEquals(result, []);
});

Deno.test("evaluateStatBadges: unlocks first_win at exactly 1 win", () => {
  const stats: UserStats = { wins: 1, totalPicksMade: 0, longestSurvivalStreak: 0, totalLeaguesJoined: 0 };
  const result = evaluateStatBadges(stats, new Set());
  assertEquals(result.includes("first_win"), true);
});

Deno.test("evaluateStatBadges: unlocks multiple badges at once", () => {
  const stats: UserStats = { wins: 1, totalPicksMade: 50, longestSurvivalStreak: 10, totalLeaguesJoined: 5 };
  const result = evaluateStatBadges(stats, new Set());
  assertEquals(result.includes("first_win"), true);
  assertEquals(result.includes("first_pick"), true);
  assertEquals(result.includes("picks_50"), true);
  assertEquals(result.includes("streak_5"), true);
  assertEquals(result.includes("streak_10"), true);
  assertEquals(result.includes("joined_5"), true);
});

Deno.test("evaluateStatBadges: skips already-unlocked badges", () => {
  const stats: UserStats = { wins: 1, totalPicksMade: 50, longestSurvivalStreak: 10, totalLeaguesJoined: 5 };
  const alreadyUnlocked = new Set(["first_win", "streak_5", "first_pick"]);
  const result = evaluateStatBadges(stats, alreadyUnlocked);
  assertEquals(result.includes("first_win"), false);
  assertEquals(result.includes("streak_5"), false);
  assertEquals(result.includes("first_pick"), false);
  assertEquals(result.includes("picks_50"), true);
});

Deno.test("evaluateStatBadges: does not unlock below threshold", () => {
  const stats: UserStats = { wins: 0, totalPicksMade: 49, longestSurvivalStreak: 4, totalLeaguesJoined: 4 };
  const result = evaluateStatBadges(stats, new Set());
  assertEquals(result.includes("first_win"), false);
  assertEquals(result.includes("picks_50"), false);
  assertEquals(result.includes("streak_5"), false);
  assertEquals(result.includes("joined_5"), false);
  // first_pick unlocks at 1, and we have 49
  assertEquals(result.includes("first_pick"), true);
});

Deno.test("evaluateStatBadges: ignores custom badges", () => {
  const stats: UserStats = { wins: 100, totalPicksMade: 100, longestSurvivalStreak: 100, totalLeaguesJoined: 100 };
  const result = evaluateStatBadges(stats, new Set());
  assertEquals(result.includes("mass_elim_survivor"), false);
  assertEquals(result.includes("full_round"), false);
});
```

- [ ] **Step 2: Run tests**

Run: `cd /home/user/Pyramid && deno test supabase/functions/check-achievements/badges.test.ts`
Expected: All 6 tests pass.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/check-achievements/badges.test.ts
git commit -m "test(PYR-107): add evaluateStatBadges unit tests"
```

---

### Task 3: check-achievements Edge Function

**Files:**
- Create: `supabase/functions/check-achievements/index.ts`
- Modify: `supabase/config.toml`

- [ ] **Step 1: Write the Edge Function**

```typescript
// Edge Function: check-achievements
// Evaluates badge unlock conditions for a user after settlement.
// Called fire-and-forget from settle-picks — failures are non-fatal.
//
// POST /check-achievements
// Headers: Authorization: Bearer <service_role_key>
// Body: { userId: string, trigger: string, context?: object }

import { getServiceClient } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { BADGE_CATALOG, evaluateStatBadges } from "./badges.ts";
import type { UserStats } from "./badges.ts";

interface RequestBody {
  userId: string;
  trigger: string;
  context?: Record<string, unknown>;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const log = createLogger("check-achievements", req);

  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Unauthorized — service role required" }, 401);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { userId, trigger, context } = body;
  if (!userId || !trigger) {
    return json({ error: "userId and trigger are required" }, 400);
  }

  const db = getServiceClient();

  // 1. Fetch already-unlocked badges
  const { data: existing, error: existErr } = await db
    .from("user_achievements")
    .select("badge_id")
    .eq("user_id", userId);

  if (existErr) {
    log.error("Failed to fetch existing achievements", existErr, { userId });
    return json({ error: "Failed to fetch achievements" }, 500);
  }

  const alreadyUnlocked = new Set((existing ?? []).map((r: { badge_id: string }) => r.badge_id));

  // If all badges already unlocked, skip evaluation
  if (alreadyUnlocked.size >= BADGE_CATALOG.length) {
    log.info("All badges already unlocked — skipping", { userId });
    return json({ checked: 0, unlocked: [] }, 200);
  }

  // 2. Compute user stats for stat-based badges
  const stats = await computeUserStats(db, userId);
  const newStatBadges = evaluateStatBadges(stats, alreadyUnlocked);

  // 3. Check custom badges based on trigger context
  const newCustomBadges: string[] = [];

  if (trigger === "mass_elimination" && !alreadyUnlocked.has("mass_elim_survivor")) {
    newCustomBadges.push("mass_elim_survivor");
  }

  if (trigger === "gameweek_settled" && context?.gameweekId && !alreadyUnlocked.has("full_round")) {
    const allSurvived = await checkFullRound(db, userId, context.gameweekId as number);
    if (allSurvived) {
      newCustomBadges.push("full_round");
    }
  }

  // 4. Insert newly unlocked badges
  const allNew = [...newStatBadges, ...newCustomBadges];
  const inserted: string[] = [];

  for (const badgeId of allNew) {
    const { error: insertErr } = await db.from("user_achievements").insert({
      user_id: userId,
      badge_id: badgeId,
      context: { trigger, ...(context ?? {}) },
    });

    if (insertErr && insertErr.code !== "23505") {
      // 23505 = unique violation (already unlocked, race condition) — safe to ignore
      log.error("Failed to insert achievement", insertErr, { userId, badgeId });
    } else {
      inserted.push(badgeId);
    }
  }

  if (inserted.length > 0) {
    log.info("Badges unlocked", { userId, badges: inserted, trigger });
  }

  log.complete("ok", { userId, checked: BADGE_CATALOG.length, unlocked: inserted });
  return json({ checked: BADGE_CATALOG.length, unlocked: inserted }, 200);
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

async function computeUserStats(
  // deno-lint-ignore no-explicit-any
  db: any,
  userId: string,
): Promise<UserStats> {
  // Wins
  const { data: winRows } = await db
    .from("league_members")
    .select("id")
    .eq("user_id", userId)
    .eq("status", "winner");
  const wins = (winRows ?? []).length;

  // Total picks
  const { count: totalPicksMade } = await db
    .from("picks")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId);

  // Leagues joined
  const { count: totalLeaguesJoined } = await db
    .from("league_members")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId);

  // Longest streak — fetch all picks ordered by league then gameweek.
  // Streak resets at league boundaries to avoid cross-league inflation.
  const { data: allPicks } = await db
    .from("picks")
    .select("league_id, result")
    .eq("user_id", userId)
    .order("league_id", { ascending: true })
    .order("gameweek_id", { ascending: true });

  let longestSurvivalStreak = 0;
  let currentStreak = 0;
  let currentLeagueId: string | null = null;
  for (const pick of (allPicks ?? []) as { league_id: string; result: string }[]) {
    if (pick.league_id !== currentLeagueId) {
      currentStreak = 0;
      currentLeagueId = pick.league_id;
    }
    if (pick.result === "survived") {
      currentStreak++;
      longestSurvivalStreak = Math.max(longestSurvivalStreak, currentStreak);
    } else if (pick.result !== "pending") {
      currentStreak = 0;
    }
  }

  return {
    wins,
    totalPicksMade: totalPicksMade ?? 0,
    totalLeaguesJoined: totalLeaguesJoined ?? 0,
    longestSurvivalStreak,
  };
}

async function checkFullRound(
  // deno-lint-ignore no-explicit-any
  db: any,
  userId: string,
  gameweekId: number,
): Promise<boolean> {
  const { data: gwPicks } = await db
    .from("picks")
    .select("result")
    .eq("user_id", userId)
    .eq("gameweek_id", gameweekId);

  if (!gwPicks || gwPicks.length === 0) return false;
  return gwPicks.every((p: { result: string }) => p.result === "survived");
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
```

- [ ] **Step 2: Add config.toml entry**

Add to `supabase/config.toml`:

```toml
[functions.check-achievements]
verify_jwt = false
```

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/check-achievements/ supabase/config.toml
git commit -m "feat(PYR-107): add check-achievements Edge Function"
```

---

### Task 4: Wire settle-picks → check-achievements

**Files:**
- Modify: `supabase/functions/settle-picks/index.ts`

- [ ] **Step 1: Add fire-and-forget achievement check after settlement**

At the end of the per-league loop (after winner detection, ~line 592), add a fire-and-forget call for each user who had a pick settled. Also add a mass-elimination trigger.

Insert after `if (winnerDeclared) summary.winnersDetected++;` (line 592):

```typescript
    // ── Check achievements (fire-and-forget) ─────────────────────────────────
    const settledUserIds = picks.map((p) => p.user_id);
    const trigger = result.isMassElim ? "mass_elimination" : "gameweek_settled";
    for (const userId of settledUserIds) {
      checkAchievements(userId, trigger, { gameweekId, leagueId, fixtureId }).catch(
        (err) => log.error("Achievement check failed (non-fatal)", err, { userId }),
      );
    }
```

Add this helper function before the `Deno.serve` block:

```typescript
async function checkAchievements(
  userId: string,
  trigger: string,
  context: Record<string, unknown>,
): Promise<void> {
  const url = `${Deno.env.get("SUPABASE_URL")}/functions/v1/check-achievements`;
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify({ userId, trigger, context }),
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/settle-picks/index.ts
git commit -m "feat(PYR-107): wire settle-picks to fire check-achievements"
```

---

### Task 5: iOS Badge Model + Static Catalog

**Files:**
- Create: `ios/Pyramid/Sources/Models/Achievement.swift`

- [ ] **Step 1: Write the model and catalog**

```swift
import Foundation

// MARK: - Achievement

struct Achievement: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let description: String
    let icon: String  // SF Symbol name

    static let catalog: [Achievement] = [
        Achievement(id: "first_win", name: "Champion", description: "Win your first league", icon: "trophy.fill"),
        Achievement(id: "streak_5", name: "On Fire", description: "Survive 5 gameweeks in a row", icon: "flame.fill"),
        Achievement(id: "streak_10", name: "Untouchable", description: "Survive 10 gameweeks in a row", icon: "bolt.shield.fill"),
        Achievement(id: "first_pick", name: "Rookie", description: "Make your first pick", icon: "hand.point.up.fill"),
        Achievement(id: "picks_50", name: "Veteran", description: "Make 50 picks", icon: "star.fill"),
        Achievement(id: "joined_5", name: "Social Butterfly", description: "Join 5 leagues", icon: "person.3.fill"),
        Achievement(id: "mass_elim_survivor", name: "Unkillable", description: "Survive a mass elimination round", icon: "arrow.counterclockwise"),
        Achievement(id: "full_round", name: "Perfect Round", description: "Survive every match in a gameweek", icon: "checkmark.seal.fill"),
    ]

    static let catalogById: [String: Achievement] = {
        Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
    }()
}

// MARK: - UserAchievement (DB row)

struct UserAchievement: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let userId: String
    let badgeId: String
    let unlockedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case badgeId = "badge_id"
        case unlockedAt = "unlocked_at"
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/Pyramid/Sources/Models/Achievement.swift
git commit -m "feat(PYR-107): add Achievement model and static badge catalog"
```

---

### Task 6: iOS Achievement Service

**Files:**
- Create: `ios/Pyramid/Sources/Services/AchievementService.swift`

- [ ] **Step 1: Write the service**

```swift
import Foundation
import Supabase

// MARK: - Protocol

protocol AchievementServiceProtocol: Sendable {
    func fetchUnlockedBadges() async throws -> [UserAchievement]
}

// MARK: - Implementation

final class AchievementService: AchievementServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseDependency.shared.client) {
        self.client = client
    }

    func fetchUnlockedBadges() async throws -> [UserAchievement] {
        let userId = try await client.auth.session.user.id.uuidString
        let rows: [UserAchievement] = try await client
            .from("user_achievements")
            .select("id, user_id, badge_id, unlocked_at")
            .eq("user_id", value: userId)
            .order("unlocked_at", ascending: false)
            .execute()
            .value
        return rows
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/Pyramid/Sources/Services/AchievementService.swift
git commit -m "feat(PYR-107): add AchievementService to fetch unlocked badges"
```

---

### Task 7: iOS AchievementsView (Badge Grid)

**Files:**
- Create: `ios/Pyramid/Sources/Features/Profile/AchievementsView.swift`

- [ ] **Step 1: Write the badge grid view**

```swift
import SwiftUI

struct AchievementsView: View {
    let unlockedBadgeIds: Set<String>

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text("Achievements")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .padding(.horizontal, Theme.Spacing.s40)

            LazyVGrid(columns: columns, spacing: Theme.Spacing.s20) {
                ForEach(Achievement.catalog) { badge in
                    badgeTile(badge: badge, unlocked: unlockedBadgeIds.contains(badge.id))
                }
            }
            .padding(.horizontal, Theme.Spacing.s40)
        }
    }

    private func badgeTile(badge: Achievement, unlocked: Bool) -> some View {
        VStack(spacing: Theme.Spacing.s10) {
            Image(systemName: badge.icon)
                .font(.system(size: 28))
                .foregroundStyle(
                    unlocked
                        ? Theme.Color.Status.Warning.resting
                        : Theme.Color.Content.Text.disabled.opacity(0.4)
                )

            Text(badge.name)
                .font(Theme.Typography.caption2)
                .foregroundStyle(
                    unlocked
                        ? Theme.Color.Content.Text.default
                        : Theme.Color.Content.Text.disabled
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.s20)
        .background(
            unlocked
                ? Theme.Color.Surface.Background.container
                : Theme.Color.Surface.Background.container.opacity(0.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r30))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r30)
                .strokeBorder(
                    unlocked
                        ? Theme.Color.Status.Warning.resting.opacity(0.3)
                        : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityLabel("\(badge.name): \(badge.description). \(unlocked ? "Unlocked" : "Locked")")
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/Pyramid/Sources/Features/Profile/AchievementsView.swift
git commit -m "feat(PYR-107): add AchievementsView badge grid component"
```

---

### Task 8: Wire Achievements into ProfileView + ViewModel

**Files:**
- Modify: `ios/Pyramid/Sources/Features/Profile/ProfileViewModel.swift`
- Modify: `ios/Pyramid/Sources/Features/Profile/ProfileView.swift`

- [ ] **Step 1: Update ProfileViewModel to load achievements**

Add to `ProfileViewModel.swift`:

```swift
// Add property
@Published var unlockedBadgeIds: Set<String> = []

// Add service dependency
private let achievementService: AchievementServiceProtocol

// Update init to accept AchievementService
init(
    authService: AuthServiceProtocol = AuthService(),
    profileService: ProfileServiceProtocol = ProfileService(),
    achievementService: AchievementServiceProtocol = AchievementService()
) {
    self.authService = authService
    self.profileService = profileService
    self.achievementService = achievementService
}

// Add method
func loadAchievements() async {
    do {
        let badges = try await achievementService.fetchUnlockedBadges()
        unlockedBadgeIds = Set(badges.map(\.badgeId))
    } catch {
        // Non-fatal — profile still works without badges
        Log.network.error("Failed to load achievements: \(error)")
    }
}
```

Update `loadStats()` to also load achievements concurrently:

```swift
func loadStats() async {
    isLoadingStats = true
    errorMessage = nil
    async let statsTask: () = loadStatsOnly()
    async let achievementsTask: () = loadAchievements()
    _ = await (statsTask, achievementsTask)
    isLoadingStats = false
}

private func loadStatsOnly() async {
    do {
        stats = try await profileService.fetchProfileStats()
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

- [ ] **Step 2: Add achievements section to ProfileView**

In `ProfileView.swift`, insert the achievements section after the stats grid and before active streaks:

```swift
// After statsGrid(stats: viewModel.stats)
AchievementsView(
    unlockedBadgeIds: viewModel.unlockedBadgeIds
)
```

- [ ] **Step 3: Commit**

```bash
git add ios/Pyramid/Sources/Features/Profile/ProfileViewModel.swift
git add ios/Pyramid/Sources/Features/Profile/ProfileView.swift
git commit -m "feat(PYR-107): wire achievements into profile screen"
```

---

### Task 9: Tests

**Files:**
- Create: `ios/PyramidTests/AchievementTests.swift`

- [ ] **Step 1: Write tests for badge catalog and profile integration**

```swift
import XCTest
@testable import Pyramid

final class AchievementTests: XCTestCase {
    func testCatalogHasExpectedBadgeCount() {
        XCTAssertEqual(Achievement.catalog.count, 8)
    }

    func testCatalogByIdMatchesCatalog() {
        for badge in Achievement.catalog {
            XCTAssertEqual(Achievement.catalogById[badge.id], badge)
        }
    }

    func testCatalogIdsAreUnique() {
        let ids = Achievement.catalog.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Badge IDs must be unique")
    }

    func testAllBadgesHaveValidSFSymbol() {
        for badge in Achievement.catalog {
            XCTAssertFalse(badge.icon.isEmpty, "\(badge.id) has empty icon")
        }
    }
}

// MARK: - ProfileViewModel Achievement Loading

@MainActor
final class ProfileViewModelAchievementTests: XCTestCase {
    func testLoadAchievementsSetsUnlockedIds() async {
        let mock = MockAchievementService(badges: [
            UserAchievement(
                id: "a1",
                userId: "user1",
                badgeId: "first_win",
                unlockedAt: Date()
            ),
            UserAchievement(
                id: "a2",
                userId: "user1",
                badgeId: "streak_5",
                unlockedAt: Date()
            ),
        ])
        let vm = ProfileViewModel(
            authService: MockAuthService(),
            profileService: StubProfileService(),
            achievementService: mock
        )

        await vm.loadAchievements()

        XCTAssertEqual(vm.unlockedBadgeIds, ["first_win", "streak_5"])
    }

    func testLoadAchievementsFailureIsNonFatal() async {
        let mock = MockAchievementService(shouldFail: true)
        let vm = ProfileViewModel(
            authService: MockAuthService(),
            profileService: StubProfileService(),
            achievementService: mock
        )

        await vm.loadAchievements()

        XCTAssertTrue(vm.unlockedBadgeIds.isEmpty)
        XCTAssertNil(vm.errorMessage, "Achievement failure should not set errorMessage")
    }
}

// MARK: - Mocks

private final class MockAchievementService: AchievementServiceProtocol {
    let badges: [UserAchievement]
    let shouldFail: Bool

    init(badges: [UserAchievement] = [], shouldFail: Bool = false) {
        self.badges = badges
        self.shouldFail = shouldFail
    }

    func fetchUnlockedBadges() async throws -> [UserAchievement] {
        if shouldFail { throw URLError(.badServerResponse) }
        return badges
    }
}

// NOTE: MockAuthService is already defined in AuthViewModelTests.swift and is
// module-scoped. Reuse it here. MockProfileService is private in ProfileViewModelTests,
// so we define a private one here to avoid collision.

private final class StubProfileService: ProfileServiceProtocol {
    func fetchProfileStats() async throws -> ProfileStats {
        .empty
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/PyramidTests/AchievementTests.swift
git commit -m "test(PYR-107): add achievement badge tests"
```

---

### Task 10: Final Verification & Push

- [ ] **Step 1: Verify all files exist**

```bash
ls -la supabase/migrations/20260321000000_user_achievements.sql
ls -la supabase/functions/check-achievements/index.ts
ls -la supabase/functions/check-achievements/badges.ts
ls -la ios/Pyramid/Sources/Models/Achievement.swift
ls -la ios/Pyramid/Sources/Services/AchievementService.swift
ls -la ios/Pyramid/Sources/Features/Profile/AchievementsView.swift
ls -la ios/PyramidTests/AchievementTests.swift
```

- [ ] **Step 2: Verify config.toml has check-achievements entry**

```bash
grep "check-achievements" supabase/config.toml
```

- [ ] **Step 3: Push branch**

```bash
git push -u origin <branch-name>
```

---

## Dependencies & Risks

| Risk | Mitigation |
|------|-----------|
| check-achievements adds latency to settle-picks | Fire-and-forget — settlement returns immediately, badge check is async |
| Race condition: two settlements unlock same badge | `UNIQUE(user_id, badge_id)` constraint + 23505 error ignored |
| Badge catalog drift between iOS and backend | IDs are the contract — iOS renders from static catalog, backend evaluates from its own. Only `badge_id` strings must match |
| Full-round badge hard to compute accurately | Conservative: only checks user's own picks in the GW, all must be "survived" |

## Out of Scope (Future)

- Push notification on badge unlock (add to check-achievements later)
- Badge detail sheet on tap (full description + unlock date)
- Leaderboard: "most badges" ranking
- Animated unlock celebration
- Shareable badge cards
