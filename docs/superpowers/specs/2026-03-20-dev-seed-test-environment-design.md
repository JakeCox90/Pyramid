# Dev Seed & Test Environment

**Date:** 2026-03-20
**Status:** Draft — pending human review
**Author:** Orchestrator agent

## Problem

The app shows a loading spinner with no content because the dev Supabase instance has no usable data. The existing seed (`supabase/seed/dev_seed.sql`) only creates 4 gameweeks from August 2025 with past deadlines, and no fixtures, leagues, members, or picks are seeded. There is no way to test the full game experience without manually creating data through the app or database.

## Goal

A self-contained dev environment where every screen has realistic content on first launch. Two in-app reset buttons (Debug builds only) allow restarting the experience without leaving the simulator.

## Design

### 1. Seed SQL — `supabase/seed/dev_seed.sql`

Replaces the current stub. All timestamps are relative to `now()` so every reset produces a fresh, pickable window.

#### Gameweeks (4)

| GW | `is_finished` | `is_current` | `deadline_at` | Fixture states |
|----|--------------|--------------|---------------|----------------|
| GW27 | true | false | `now() - 5 days` | No fixtures seeded (historical reference only — needed for Jordan M's elimination) |
| GW28 | true | false | `now() - 2 days` | All 10 FT |
| GW29 | false | true | `now() + 2 hours` | 2 FT, 2 live, 6 NS (kickoff tomorrow) |
| GW30 | false | false | `now() + 8 days` | 10 NS (future) |

#### Teams

All 20 real Premier League teams with their API-Football IDs, names, and logo URLs (e.g. `https://media.api-sports.io/football/teams/42.png`). Inlined into fixture and pick data — no separate `teams` table required.

#### Fixtures (30 total, 10 per GW for GW28-30)

- **GW28:** 10 completed matches with realistic scorelines (e.g. Arsenal 2-1 Chelsea). All `status = 'FT'`. Includes `home_team_logo` and `away_team_logo` URLs for all teams.
- **GW29:** Mixed states to show the full matchday experience:
  - 2 FT with final scores (settled)
  - 2 live — 1 in `'1H'` (kicked off 30 mins ago), 1 in `'2H'` (kicked off 75 mins ago), both with mid-game scores
  - 6 NS — `kickoff_at = now() + 1 day`, pickable
- **GW30:** 10 future matches, all `status = 'NS'`, `kickoff_at = now() + 9 days`.
- **GW27:** No fixtures seeded — exists only as a gameweek reference for elimination history.

All fixtures include `home_team_logo` and `away_team_logo` columns populated with API-Football CDN URLs.

#### Users (21 — 1 test user + 20 bots)

| # | Email | Display Name | Username | Auth | Purpose |
|---|-------|-------------|----------|------|---------|
| 1 | `test@pyramid.app` | Jake | `jake` | Real auth account (existing dev credentials) | Primary test user |
| 2 | `bot-alex@pyramid.dev` | Alex R | `alexr` | Minimal `auth.users` row | Active survivor |
| 3 | `bot-sam@pyramid.dev` | Sam K | `samk` | Minimal `auth.users` row | Eliminated GW28 |
| 4 | `bot-jordan@pyramid.dev` | Jordan M | `jordanm` | Minimal `auth.users` row | Eliminated GW27 |
| 5 | `bot-chris@pyramid.dev` | Chris P | `chrisp` | Minimal `auth.users` row | Winner (League 3) |
| 6–21 | `bot-{name}@pyramid.dev` | 16 more realistic names | `bot{n}` | Minimal `auth.users` row | Fill out league rosters |

The full bot roster (20 bots) uses varied realistic names (e.g. "Tom W", "Priya S", "Dan H", "Olivia C", etc.) so league member lists look authentic. Each bot gets a deterministic UUID (`00000000-0000-0000-0000-00000000000{N}` for 2-9, `00000000-0000-0000-0000-0000000000{NN}` for 10-21).

**Bot user auth strategy:** The `profiles` table has a FK constraint to `auth.users(id)`. All 20 bots require minimal rows in `auth.users` with deterministic UUIDs. The seed SQL inserts these using service role privileges:

```sql
INSERT INTO auth.users (id, email, encrypted_password, aud, role, ...)
VALUES ('00000000-0000-0000-0000-000000000002', 'bot-alex@pyramid.dev', '', 'authenticated', 'authenticated', ...);
-- ... repeated for all 20 bots
```

These are not real login accounts — they exist solely to satisfy the FK constraint. The `encrypted_password` is empty so they cannot be used to authenticate.

**Test user profile:** The seed UPSERTs the test user's profile with a known display name, username, and avatar URL so the Profile screen has content.

#### Leagues (3)

| League | Name | Type | Status | Join Code | `created_by` | `start_gameweek_id` | Members | Test user state |
|--------|------|------|--------|-----------|-------------|---------------------|---------|-----------------|
| 1 | Office Legends | free | active | `OFFICE1` | Test user | GW27 | 21 (12 alive, 9 eliminated) | Alive, survived GW28, no GW29 pick yet |
| 2 | Sunday Club | free | active | `SUNDAY1` | Test user | GW28 | 16 (all alive) | Alive, survived GW28, no GW29 pick yet |
| 3 | Champions | free | completed | `CHAMP1` | Test user | GW27 | 15 (1 winner, 14 eliminated) | Winner |

All leagues set `created_by` to the test user's UUID. `start_gameweek_id` references a seeded gameweek. Bots are distributed across leagues — some appear in multiple leagues (realistic). Not every bot is in every league.

#### League Members

**Office Legends (active, mid-season, started GW27) — 21 members:**
- Test user: `status = 'active'`
- 11 bots: `status = 'active'` (including Alex R, Chris P, and 9 others)
- 5 bots: `status = 'eliminated'`, `eliminated_in_gameweek_id` = GW28 (including Sam K)
- 4 bots: `status = 'eliminated'`, `eliminated_in_gameweek_id` = GW27 (including Jordan M)

This gives the league a realistic attrition curve — started with 21, lost 4 in GW27, lost 5 more in GW28, 12 remain.

**Sunday Club (active, early, started GW28) — 16 members:**
- Test user + 15 bots: all `status = 'active'`

Early-stage league — nobody eliminated yet. Shows the "everyone still alive" state.

**Champions (completed, started GW27) — 15 members:**
- Test user: `status = 'winner'`
- 14 bots: `status = 'eliminated'` (spread across GW27 and GW28)

#### Picks

**GW28 (finished, all settled):**
- All alive members in League 1 and League 2 have picks with `result = 'survived'`
- Eliminated members (Sam K in League 1) have picks with `result = 'eliminated'`
- `is_locked = true`, `settled_at` set
- Each pick uses a different team to build realistic used-team history

**GW29 (current):**
- Bot members who are alive have picks on the 2 FT and 2 live fixtures (locked, some settled)
- Test user has NO pick in any league — so you can submit one
- Eliminated members have no GW29 picks

**Champions League (historical):**
- Picks seeded for at least GW27 and GW28 to give League 3 a visible pick history on the completed league detail screen
- Test user's picks all show `result = 'survived'`; bot picks show a mix of survived/eliminated matching their final statuses

**Used Teams:** `used_teams` is a VIEW derived from `picks` — no separate seeding required. The pick data automatically populates the view, enforcing the no-repeat constraint for GW29 pick submission.

### 2. Reset Edge Function — `supabase/functions/reset-dev-data/index.ts`

A service-role Edge Function that wipes and re-seeds the dev database.

#### Safety

- Reads `ENVIRONMENT` env var (set in Supabase project settings)
- Refuses to execute unless `ENVIRONMENT === 'dev'` — returns `403 Forbidden` with message `"Reset is only available in dev environment"`
- Uses the Supabase service role key (from env) for all DB operations — this is required to bypass RLS and to write to `auth.users`
- Does NOT accept user JWTs for the actual DB operations (RLS would block truncation)

#### Modes

**`mode: "game"` (Reset Game Data)**

Truncates using `TRUNCATE ... CASCADE` in a single statement to handle all FK relationships:

```sql
TRUNCATE settlement_log, picks, league_members, leagues, fixtures, gameweeks CASCADE;
```

Then re-inserts all seed data (gameweeks, fixtures, bot auth.users rows, bot profiles, leagues, league members, picks).

Leaves the test user's `profiles` row and `auth.users` row untouched. Bot `auth.users` and `profiles` rows are re-created as part of the seed.

**`mode: "full"` (Reset Everything)**

Same as `game` mode, plus:
1. Deletes bot rows from `profiles` (the `CASCADE` on `auth.users` FK handles this if we delete from `auth.users`)
2. Deletes bot rows from `auth.users`
3. Deletes the test user's `profiles` row (but NOT their `auth.users` row — session stays valid)
4. Returns `{ success: true, mode: "full", clearOnboarding: true }` — the iOS client reads `clearOnboarding` and clears the UserDefaults flag

After truncation, `game` seed data is NOT re-inserted in `full` mode — the user gets a genuinely empty experience (no leagues to see, must join via code after onboarding).

Wait — on reflection, `full` mode should still seed the gameweeks, fixtures, and bot users/leagues so there's something to join. It just shouldn't auto-enrol the test user in any league. Let me clarify:

**`mode: "full"` re-seeds everything EXCEPT league membership for the test user.** Leagues exist with bot members only. The test user can join via join codes (`OFFICE1`, `SUNDAY1`, `CHAMP1`) after completing onboarding.

#### Request/Response

```
POST /reset-dev-data
Headers: Authorization: Bearer <service-role-key>
Body: { "mode": "game" | "full", "userId": "<current-user-uuid>" }

Response 200: { "success": true, "mode": "game" | "full", "clearOnboarding": false | true }
Response 403: { "error": "Reset is only available in dev environment" }
```

The iOS client passes the service role key from `Debug.xcconfig` (already available in Debug builds for other service-role functions).

### 3. iOS Debug UI

#### Profile Screen Changes — `ProfileView.swift`

Add a "Developer Tools" section inside `#if DEBUG`, at the bottom of the profile screen:

```
┌─────────────────────────────────────────┐
│  Developer Tools                         │
│                                         │
│  [Reset Game Data]                      │
│  Resets leagues, picks, and fixtures.   │
│  You stay logged in.                    │
│                                         │
│  [Reset Everything]                     │
│  Full reset including onboarding flow.  │
└─────────────────────────────────────────┘
```

Both buttons show a loading spinner overlay while the Edge Function runs.

#### DevResetService — `DevResetService.swift` (new, `#if DEBUG` only)

A simple service that:
1. Calls `POST /reset-dev-data` with the service role key and appropriate mode
2. Parses the response
3. Returns the result to the caller

#### AppState Changes — `AppState.swift`

Add a `resetToOnboarding()` method that:
1. Sets `hasCompletedOnboarding = false` in UserDefaults
2. Sets `showOnboarding = true`
3. Triggers RootView to show the onboarding flow

#### Post-Reset Behavior

- **Game reset:** Call `homeViewModel.refresh()` — user lands on Home with fresh seeded data
- **Full reset:** Call `appState.resetToOnboarding()` — user lands on onboarding carousel, then progresses through empty home → join seeded leagues via join codes

### 4. Reset Script — `scripts/reset-dev.sh` (optional convenience)

A shell script for terminal-based reset (useful before the iOS button is built):

```bash
#!/bin/bash
set -euo pipefail

# Safety check — only run against dev database
if [[ -z "${DEV_DATABASE_URL:-}" ]]; then
  echo "ERROR: DEV_DATABASE_URL not set" >&2
  exit 1
fi

if [[ "$DEV_DATABASE_URL" != *"qvmzmeizluqcdkcjsqyd"* ]]; then
  echo "ERROR: DEV_DATABASE_URL does not point to the dev Supabase instance" >&2
  exit 1
fi

supabase db reset --db-url "$DEV_DATABASE_URL"
echo "Dev database reset and re-seeded."
```

## Screens Enabled for Testing

| Screen / Flow | What you'll see |
|---------------|----------------|
| Home — hero status card | "3 leagues, 2 picks needed" with countdown to GW29 deadline |
| Home — league cards | 3 cards: Office Legends (pick needed), Sunday Club (pick needed), Champions (completed) |
| Home — live match card | 2 live fixtures with scores updating |
| Picks — fixture list | 10 GW29 fixtures: 2 with results, 2 live, 6 pickable |
| Picks — submit a pick | Tap a team on an NS fixture, confirm, see celebration |
| Picks — used teams greyed out | Teams picked in GW28 are unavailable |
| Picks — locked state | FT/live fixture picks show as locked |
| League detail — members | Mix of alive/eliminated members with statuses |
| League detail — completed | Champions shows winner banner and final standings |
| Profile | Your profile with avatar, display name, stats |
| Onboarding | Full first-time flow (after "Reset Everything") |
| Empty home → join league | After full reset, join "Office Legends" with code `OFFICE1` |

## Files to Create or Modify

| File | Action | Description |
|------|--------|-------------|
| `supabase/seed/dev_seed.sql` | Rewrite | Comprehensive rolling seed with all tables |
| `supabase/functions/reset-dev-data/index.ts` | Create | Reset + re-seed Edge Function |
| `ios/Pyramid/Sources/Features/Profile/ProfileView.swift` | Modify | Add Developer Tools section (`#if DEBUG`) |
| `ios/Pyramid/Sources/Services/DevResetService.swift` | Create | Edge Function client for reset (`#if DEBUG`) |
| `ios/Pyramid/Sources/App/AppState.swift` | Modify | Add `resetToOnboarding()` method |
| `scripts/reset-dev.sh` | Create | Terminal convenience script with safety checks |

## Out of Scope

- Multi-user testing / device handoff (future)
- Automated UI test harness (future)
- Paid league seed data (paid features are toggled but not the focus now)
- API-Football integration testing (seed data is fully static)
- Production data — this touches dev Supabase only
