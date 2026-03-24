# PYR-107: Achievements & Badges System — Design Spec

> **Status:** Approved
> **Author:** Orchestrator + Human
> **Date:** 2026-03-23
> **Linear:** PYR-107
> **Milestone:** Community & Social → V3: Global Stats & Achievements

---

## 1. Goal

A 20-badge achievement system that rewards survival mastery and commemorates narrative moments. Badges are a passive delight indicator — players don't grind for them, they discover them. Think Duolingo's engagement model applied to a weekly binary-outcome game: surprising, earned, never annoying.

## 2. Design Principles

- **Passive delight, not obligation.** No daily streaks, no push notifications nagging about incomplete collections, no progress bars demanding attention.
- **Moments over metrics.** The best badges commemorate something that *happened to you*, not something you optimised for.
- **Cosmetic only (V1).** No gameplay impact, no functional rewards. The badge itself is the reward.
- **Agnostic components.** All new UI primitives (Toast, IconBadge, DetailSheet) are design-system-level, reusable across any feature. The achievement system configures them, doesn't own them.

## 3. Badge Catalog (20 badges)

### 3.1 Tiered Tracks (4 tracks, 12 badges)

#### Survival Streak

| Tier | Name | Condition |
|------|------|-----------|
| 1 | Survivor | 3 consecutive GW survivals in a single league |
| 2 | Iron Wall | 5 consecutive GW survivals in a single league |
| 3 | Untouchable | 10 consecutive GW survivals in a single league |

**Mass elimination note:** GWs where a mass elimination occurred (all active members eliminated, all reinstated per game rules §4.5) do NOT count toward survival streaks. The reinstatement is a safety net, not a genuine survival. The evaluation query must check for mass elimination events on that league/GW.

#### Champion

| Tier | Name | Condition |
|------|------|-----------|
| 1 | Champion | Win 1 league (lifetime) |
| 2 | Dynasty | Win 3 leagues (lifetime) |
| 3 | Legend | Win 5 leagues (lifetime) |

#### Veteran

| Tier | Name | Condition |
|------|------|-----------|
| 1 | Seasoned | 25 total survivals (settled, non-void, lifetime) |
| 2 | Veteran | 50 total survivals |
| 3 | Centurion | 100 total survivals |

#### Longshot

| Tier | Name | Condition |
|------|------|-----------|
| 1 | Longshot I | 3 underdog wins (picked team had <30% pre-match win probability) |
| 2 | Longshot II | 5 underdog wins |
| 3 | Longshot III | 10 underdog wins |

**Underdog definition:** The picked team's pre-match win probability is below 30%, derived from betting odds stored in the `fixtures` table. This uses actual match context, not league table position.

### 3.2 Singular Narrative Badges (8 badges)

| Badge | Trigger |
|-------|---------|
| **Against the Odds** | Survive a GW where 50%+ of *active* league members were eliminated that GW. Denominator is members with `status = 'active'` at the start of the gameweek, not total league members. |
| **Landslide** | Your picked team wins by 4+ goals |
| **Last One Standing** | Be the sole survivor when all other active league members are eliminated in the same GW. Does NOT trigger during mass elimination events (where all active members were eliminated and reinstated per game rules §4.5). |
| **Giant Killer** | Survive by picking a team with <30% pre-match win probability (single moment, vs Longshot which is cumulative). Giant Killer and Longshot track the same underdog events — Giant Killer fires on the first occurrence, Longshot tracks the running count. |
| **Nerves of Steel** | Your picked team wins with a goal scored in the 85th minute or later, having been losing or drawing prior |
| **Phoenix** | Get eliminated from any league, then join a new league and win it |
| **Full House** | Submit a pick in every GW of a complete round where the user was active, with no missed deadlines. Evaluated at league completion — the range is from the league's first gameweek to the GW where the league reached `completed` status. Only applies to users who survived to the round's end (eliminated users cannot achieve Full House for that round). |
| **Icarus** | Survive 5+ consecutive GWs in a league, then get eliminated |

### 3.3 Deliberately Excluded

- Time-pressure badges ("picked within 1 minute of deadline") — encourages bad UX behaviour
- Pure participation badges ("joined 5 leagues", "made 50 picks") — feels like filler, rewards showing up not skill
- Cosmetic unlock rewards — out of scope for V1

## 4. Data Model

### 4.1 `user_achievements` table

```sql
CREATE TABLE user_achievements (
    user_id        uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id text        NOT NULL,
    unlocked_at    timestamptz NOT NULL DEFAULT now(),
    context        jsonb,
    PRIMARY KEY (user_id, achievement_id)
);
```

- Composite PK makes unlocks idempotent — `INSERT ... ON CONFLICT DO NOTHING`
- `context` stores the narrative moment: `{"league_id": "...", "gameweek": 28, "margin": 5, "team": "Arsenal"}`
- No `seen` column — new badge detection handled client-side via local cache

### 4.2 RLS Policies

- `SELECT`: Users can read their own rows (`auth.uid() = user_id`)
- `INSERT/UPDATE/DELETE`: Service role only (all writes come from settlement)
- No client-side writes

### 4.3 Odds Enrichment — `fixtures` table

Add columns to existing `fixtures` table:

```sql
ALTER TABLE fixtures ADD COLUMN home_win_prob numeric(5,2);  -- e.g. 27.30
ALTER TABLE fixtures ADD COLUMN draw_prob     numeric(5,2);  -- e.g. 33.50
ALTER TABLE fixtures ADD COLUMN away_win_prob numeric(5,2);  -- e.g. 39.20
```

Populated by `sync-fixtures` Edge Function from API-Football's pre-match odds endpoint. Used by Longshot (I/II/III) and Giant Killer evaluation. Stored as decimal percentages to avoid rounding errors at the 30% threshold boundary. The underdog check is strictly `< 30.00`.

### 4.4 Badge Definitions — Static Config (not DB)

Badge metadata (name, description, icon, track, tier) lives as static constants in both:
- iOS: `AchievementCatalog.swift`
- Edge Function: inline constant in `settle-picks`

Not stored in the database. The DB only records *what users have unlocked*, not *what badges exist*. This keeps badge definitions versioned in code and avoids a config table.

## 5. Backend Architecture

### 5.1 Evaluation Function — Hybrid TypeScript + SQL

Achievement evaluation is a **TypeScript function within `settle-picks`**, not a standalone SQL function. This is necessary because Nerves of Steel requires an HTTP call to API-Football for match events, which cannot be done from Postgres.

The flow:
1. `settle-picks` settles a league for a gameweek (existing logic)
2. After settlement, TypeScript calls `evaluateAchievements(userId, leagueId, gameweek, matchEvents)`:
   - Fetches match events from API-Football (for Nerves of Steel) — graceful degradation if this fails
   - Calls a **SQL helper function** `check_and_insert_achievements(target_user_id, league_id, gameweek, match_events_json)` that runs all DB-derivable badge checks and inserts unlocks
   - The SQL function receives match event data as a jsonb parameter so it can evaluate Nerves of Steel within the same transaction
3. All inserts use `ON CONFLICT DO NOTHING` for idempotency

### 5.2 Evaluation Triggers by Badge

#### At per-GW settlement (called from `settle-picks`):

| Badge | Data Required |
|-------|---------------|
| Survival Streak (1/2/3) | Consecutive survivals in the settled league |
| Veteran (1/2/3) | Total survivals across all leagues |
| Longshot (1/2/3) | Picked team's pre-match win prob (<30%) + team won |
| Giant Killer | Same as Longshot, single instance |
| Against the Odds | User survived + 50%+ of league eliminated this GW |
| Last One Standing | All other members eliminated this GW, user survived |
| Landslide | Goal margin >= 4 for user's picked team |
| Nerves of Steel | Match events: 85th min+ goal, team was losing/drawing prior |
| Icarus | User eliminated + had 5+ consecutive survivals prior in this league |

#### At league completion (winner detection):

| Badge | Data Required |
|-------|---------------|
| Champion (1/2/3) | Total lifetime wins |
| Phoenix | User has any prior elimination + just won this league |

#### At round-end settlement:

| Badge | Data Required |
|-------|---------------|
| Full House | All GWs in the round have a pick for this user in this league |

### 5.3 Nerves of Steel — Match Events

`settle-picks` already fetches fixture data at settlement time. Extended to also fetch match events (goals with minute timestamps) from API-Football for the relevant fixture. Event data is checked in-memory during evaluation and discarded — no new table.

**Graceful degradation:** If the match events API call fails, Nerves of Steel simply doesn't evaluate for that fixture. It never blocks settlement or other badge evaluation.

### 5.4 Backfill Strategy

A one-time migration script runs `evaluate_achievements` for every user with historical data.

**Backfillable:** Survival Streak, Champion, Veteran, Against the Odds, Last One Standing, Landslide, Phoenix, Full House, Icarus — all derivable from existing `picks`, `league_members`, and `fixtures` data.

**Not backfillable (start counting from deployment):**
- Longshot (I/II/III) — requires pre-match odds not historically stored
- Giant Killer — same reason
- Nerves of Steel — requires match event data not historically stored

## 6. iOS Architecture

### 6.1 Design System Components (agnostic, reusable)

All created in `Shared/DesignSystem/Components/` and registered in the design system browser.

#### `Toast.swift`
Configurable slide-in banner. No knowledge of achievements or any specific feature.

```swift
struct ToastConfiguration {
    let icon: String           // SF Symbol name
    let title: String
    let subtitle: String?
    let style: BadgeIntent     // success / info / warning / neutral
    let duration: TimeInterval // default 3s
}
```

#### `ToastManager.swift`
Observable queue that any feature can push toasts to. Injected via environment. Handles sequencing (one at a time), animation (0.3s slide), and auto-dismissal.

```swift
@MainActor
final class ToastManager: ObservableObject {
    func show(_ config: ToastConfiguration)
    func show(icon: String, title: String, subtitle: String?, style: BadgeIntent)
}
```

#### `IconBadge.swift`
Icon + label + active/inactive state + optional tier indicator.

```swift
struct IconBadgeConfiguration {
    let icon: String           // SF Symbol
    let label: String
    let isActive: Bool         // unlocked vs greyed/locked
    let tier: Int?             // nil = no tier indicator
    let style: BadgeIntent     // reuses existing enum
}
```

#### `DetailSheet.swift`
Generic detail sheet for any entity. Hero icon, title, subtitle, metadata rows, body text.

```swift
struct DetailSheetConfiguration {
    let icon: String
    let iconStyle: BadgeIntent
    let title: String
    let subtitle: String?
    let metadata: [(label: String, value: String)]
    let body: String?
}
```

### 6.2 Feature Files (achievement-specific)

#### `AchievementCatalog.swift`
Static badge definitions. Single source of truth on iOS for badge metadata.

```swift
struct BadgeDefinition {
    let id: String              // e.g. "survival_streak_1", "icarus"
    let name: String            // e.g. "Iron Wall"
    let description: String     // e.g. "Survive 5 consecutive gameweeks"
    let icon: String            // SF Symbol
    let track: String?          // nil for singular badges
    let tier: Int?              // nil for singular badges
    let style: BadgeIntent
}
```

#### `Achievement.swift` (Model)
```swift
struct Achievement: Codable, Identifiable {
    let achievementId: String
    let unlockedAt: Date
    let context: [String: AnyCodable]?

    var id: String { achievementId }

    enum CodingKeys: String, CodingKey {
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
        case context
    }
}
```

#### `AchievementService.swift`
Protocol-based service. Fetches unlocked achievements from `user_achievements` table.

#### `AchievementsViewModel.swift`
- Fetches unlocked list via AchievementService
- Merges with AchievementCatalog to produce display models
- Manages "new badge" detection: compares server state against UserDefaults-cached set
- Triggers toast via ToastManager for new unlocks

#### `AchievementsView.swift`
Grid of all badges grouped by track (tiered) and singular. Unlocked badges rendered with full colour IconBadge, locked badges greyed with silhouette. Tapping opens DetailSheet.

#### `AchievementDetailSheet` usage
Not a custom view — `AchievementsView` presents a `DetailSheet` configured with badge data + context story.

### 6.3 Integration Points

- **`RootView`** — Toast overlay (single instance, reads from ToastManager)
- **`ProfileView`** — New "Achievements" section with NavigationLink to AchievementsView, plus inline preview of most recent unlocks
- **`ComponentBrowserView`** — Toast, IconBadge, DetailSheet registered for design system browser

### 6.4 New Badge Detection (Toast Flow)

1. App comes to foreground → AchievementsViewModel fetches unlocked list from Supabase
2. Compares against locally cached achievement IDs (UserDefaults)
3. New IDs found → map to BadgeDefinition → push ToastConfiguration(s) to ToastManager
4. ToastManager shows sequentially (3s each, 0.3s slide animation)
5. Update local cache after all toasts displayed

## 7. Out of Scope (V2+)

- Featured badge displayed on profile / leaderboard / league views
- Functional rewards (unlock themes, etc.)
- Social sharing of badges
- Badge flair next to name in league member lists
- Push notifications for badge unlocks
- Badge rarity stats ("only 3% of players have this")

## 8. Dependencies

- **PYR-104** (user_stats table) — merged, provides stats infrastructure
- **PYR-106** (leaderboard) — merged, provides LeaderboardService pattern to follow
- **`sync-fixtures`** — must be extended to fetch and store pre-match odds
- **`settle-picks`** — must be extended to call `evaluate_achievements` and fetch match events
- **API-Football** — odds endpoint (pre-match) + events endpoint (goal minutes)

## 9. Acceptance Criteria

- [ ] `user_achievements` table exists with composite PK, RLS policies, context jsonb
- [ ] `fixtures` table has `home_win_prob`, `draw_prob`, `away_win_prob` columns
- [ ] `sync-fixtures` populates odds columns from API-Football
- [ ] `check_and_insert_achievements` SQL helper function checks all 20 badge conditions
- [ ] `settle-picks` calls `evaluateAchievements` TypeScript function after each league settlement, which fetches match events and delegates to the SQL helper
- [ ] Backfill migration unlocks historically-earned badges for existing users
- [ ] `Toast`, `ToastManager`, `IconBadge`, `DetailSheet` exist as design system components
- [ ] All design system components registered in ComponentBrowserView
- [ ] `AchievementsView` shows all 20 badges — unlocked (colour) and locked (greyed)
- [ ] Tapping a badge opens DetailSheet with context story
- [ ] New badges trigger toast on app foreground
- [ ] Toast auto-dismisses after 3s with slide animation
- [ ] ProfileView has "Achievements" section linking to AchievementsView
- [ ] All UI uses Theme tokens, dark mode compatible
- [ ] Nerves of Steel gracefully degrades if match events API fails
- [ ] Longshot/Giant Killer badges only count from deployment (no backfill for odds-dependent badges)
- [ ] All badge unlocks are idempotent (safe to re-run settlement)
