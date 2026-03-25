# Gameweek Story — Design Spec

**Date:** 2026-03-23
**Status:** Draft
**Branch:** TBD

## Overview

A Spotify Wrapped / Instagram Stories-style tap-through experience for each gameweek in a league. After settlement, users tap through a sequence of full-screen cards that tell the story of what happened — building tension before revealing their own result. After the last card, users land on a scrollable overview with the full recap.

The goal: make the end of each gameweek feel like an **event**, not a data refresh.

## Story Card Sequence

7 possible cards per gameweek per league. Conditional cards are omitted entirely when not relevant — no blank states.

| # | Card | Type | Content |
|---|------|------|---------|
| 1 | Title | Core | GW number, league name, players remaining, progress dots (green tick = alive, red X = eliminated) |
| 2 | Headline | Core | AI-generated editorial headline (~5 words) + narrative body (~60 words) |
| 3 | Biggest Upset | Conditional | Shock result scoreline, team crests, casualty count. Only shown if a loss caused eliminations |
| 4 | Eliminated | Conditional | Count + list of eliminated players with their picks. Only shown if eliminations happened |
| 5 | Wildcard | Optional | Most contrarian pick of the week — survived or not. Skipped if all picks were mainstream |
| 6 | Your Pick | Core | Team crest, result, survived/eliminated/void reveal. The climax of the story |
| 7 | Still Standing | Core | Remaining player count, player avatars, "You" highlighted. Replaced by "You Won" variant if user is the sole survivor |

A quiet gameweek with no eliminations could be as few as 4 cards (Title → Headline → Your Pick → Still Standing).

### Your Pick — Variant Handling

| Scenario | Card content |
|----------|-------------|
| User survived | Team crest, result, "You survived" |
| User eliminated | Team crest, result, "Eliminated" |
| User's pick voided, repicked | Show final settled pick only |
| User auto-eliminated (missed deadline) | No team crest. "You missed the deadline — eliminated" |
| User's only pick voided, survived | "Pick voided — survived" with explanatory text |

### Still Standing — Variant Handling

| Scenario | Card content |
|----------|-------------|
| Multiple players remain | Standard: count + avatars |
| User is the sole survivor (league won) | Replace with "You Won" card — celebration variant |
| User was eliminated | Show as "League Status" — remaining players without "You" highlight |
| Mass elimination (all eliminated, all reinstated) | Show all players as surviving, with "Everyone survived — mass elimination reversed" note |

### Mass Elimination

When all remaining players are eliminated in the same gameweek, the game reinstates everyone (per game rules). The story should acknowledge this:

- **Eliminated card** shows all players as eliminated with a "Mass Elimination" label
- **Additional card** (after Eliminated): "Everyone Lives" — explains mass elimination rule, all players reinstated
- **Still Standing** card shows all players back in

### Card Visibility Rules

| Card | Show when |
|------|-----------|
| Title | Always |
| Headline | `gameweek_stories` row exists with non-null headline |
| Biggest Upset | `upset_fixture_id` is non-null |
| Eliminated | At least 1 player eliminated this gameweek |
| Wildcard | `wildcard_pick_id` is non-null |
| Your Pick | Always |
| Still Standing | Always |

## Full Overview

After the last story card, users swipe up to reach a scrollable recap screen containing:

- **Progress dots** — green circles with white tick (alive), faded red with X (eliminated)
- **Stats bar** — survived / eliminated / already out counts
- **Upset banner** — the result that caused the most damage (conditional)
- **All picks** — survived players listed first, then eliminated, each showing team + result
- **Dot count** — e.g. "8/20"

The overview is also directly accessible from the league detail screen without going through the story.

## Navigation & Interaction

Follows Instagram Stories / Spotify Wrapped conventions:

- **Tap right** (70% of screen width) → next card
- **Tap left** (30%) → previous card
- **Progress bars** at top, segmented per card, fill as user advances
- Subtle tap flash feedback
- **Last card** shows "Swipe up for full recap" → transitions to overview. Also provide an explicit "View Recap" button as fallback (swipe-up may conflict with iOS navigation gestures)

### Entry Points

| Entry | Behaviour |
|-------|-----------|
| Push notification (after settlement) | Opens story from card 1 (requires deep link support — deferred if not yet implemented) |
| League detail → "GW Recap" button | Opens story from card 1 |
| League detail → direct overview link | Goes straight to overview |

### Story View State

- Track `story_viewed` per user per league per gameweek
- First visit → story auto-plays from card 1
- Return visits → goes to overview, with "Replay story" option
- Unviewed stories show a badge/indicator on the league row

## AI Editorial Generation

### Trigger

Runs as part of the settlement pipeline, after all picks for a gameweek in a league are settled.

### Edge Function: `generate-gameweek-story`

- Called once per league per gameweek after settlement completes
- **Input:** all picks, results, eliminations, survivors for that league + gameweek
- **Output:** headline (max ~5 words), narrative body (max ~60 words), wildcard pick ID (optional)

### Prompt Strategy

- Tone: to be defined by a tone-of-voice guide (forthcoming). Prompt will pull tone guidance from a config source so it can be updated without code changes.
- Always references specific players by first name and their actual picks/results
- Highlights drama: upsets, clusters of same-pick eliminations, brave picks, narrow escapes
- Never generic — every story should feel unique to that league's gameweek

### Settlement Integration

`settle-picks` already checks `isGameweekFullySettled()` after each fixture settlement and runs `detectAndDeclareWinner()` when true. Story generation hooks into the same check:

1. `settle-picks` settles a fixture's picks for a league
2. Checks `isGameweekFullySettled()` — if false, stop
3. If true: run `detectAndDeclareWinner()` (existing)
4. Then call `generate-gameweek-story` via `fetch()` for that league + gameweek
5. Story generation is non-blocking — settlement succeeds even if story generation fails

This means story generation only fires once per league per gameweek, after all fixtures (including late kickoffs) are settled.

### Biggest Upset Selection

The "biggest upset" is the fixture that caused the most eliminations within that league's gameweek. Deterministic, requires no external odds data, directly relevant to the league's story. If no fixture caused any eliminations, the Upset card is omitted.

### Wildcard Selection

The "wildcard pick" is the pick chosen by the fewest players in that league for that gameweek (minimum: only 1 player picked that team). If multiple single-pick teams exist, prefer the one that survived. If no team was picked by only 1 player, skip the Wildcard card.

### Fallback

If AI generation fails, the Headline card is skipped. The story runs with structured data only (6 cards max). The overview is unaffected. No retry for v1 — failed generations can be backfilled manually if needed.

## Data Model

### New table: `gameweek_stories`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK, default gen_random_uuid() |
| league_id | uuid | FK → leagues, not null |
| gameweek | int | not null |
| headline | text | AI-generated, ~5 words |
| body | text | AI-generated, ~60 words |
| wildcard_pick_id | uuid | FK → picks, nullable |
| upset_fixture_id | int | FK → fixtures, nullable — the fixture that caused most eliminations in this league |
| generated_at | timestamptz | default now() |
| idempotency_key | text | unique constraint, format: `{league_id}_{gameweek}` |

Idempotency follows existing settlement pattern — unique constraint on `idempotency_key`, catch Postgres error `23505` as no-op on re-run.

### New table: `story_views`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK, default gen_random_uuid() |
| user_id | uuid | FK → auth.users, not null |
| league_id | uuid | FK → leagues, not null |
| gameweek | int | not null |
| viewed_at | timestamptz | default now() |

Unique constraint on `(user_id, league_id, gameweek)`. Written client-side on first story view (upsert, ignore conflict).

### Row Level Security

**`gameweek_stories`:**
- SELECT: user must be a member of the league (`league_id` in user's `league_members`)
- INSERT/UPDATE/DELETE: service role only (edge function writes)

**`story_views`:**
- SELECT: user can read own rows only (`user_id = auth.uid()`)
- INSERT: user can insert own rows only (`user_id = auth.uid()`)
- UPDATE/DELETE: denied

## Data Assembly

Story is assembled client-side from two sources:

1. **Structured data** (already exists): picks, results, player statuses, fixtures — fetched via existing league detail queries
2. **Story data** (new): the `gameweek_stories` row — single query: `GET /rest/v1/gameweek_stories?league_id=eq.{id}&gameweek=eq.{gw}`

iOS ViewModel builds an ordered array of card view models, including only cards that meet their visibility condition. The view renders the array — no blank or hidden cards.

Overview stats (survived count, eliminated count, already-out count) are derived client-side from the structured data.

## Visual Design

The wireframes produced during brainstorming are structural references only. **Final card designs will come from Figma.**

Key architectural requirement for the card rendering system:
- **Per-card theming must be supported** — each card type should accept its own background, color scheme, and typography overrides
- This allows individual card designs to evolve independently
- The card container/navigation chrome (progress bars, tap zones) is shared; the card content area is fully customisable per type

### Interaction Design

- Cards crossfade with subtle scale transition
- Progress bar fills smoothly on advance
- Tap flash provides immediate feedback on interaction

## Out of Scope (for v1)

- Auto-advancing timer (Wrapped uses this; we use manual tap only for now)
- Sharing/screenshot of individual story cards
- Story reactions or comments
- Historical story playback (only current/most recent gameweek)
- Per-card theming in v1 (system supports it, but v1 ships with consistent styling)

## Accessibility

- VoiceOver: each card should announce its content when active (card type + key information)
- Swipe gestures as alternative to tap zones for VoiceOver users
- Support reduced motion: disable scale transitions, use instant crossfade
- Progress bars should have accessibility labels ("Card 3 of 7")
