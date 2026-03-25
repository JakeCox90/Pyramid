# Simulator Walkthrough — Screen-by-Screen Guide

> Annotated walkthrough of every screen in the app as of 2026-03-25. Screenshots where available, detailed descriptions for all screens.

---

## How to Navigate

The app has 3 tabs at the bottom: **Home**, **Leagues**, **Profile**. Every screen is reachable from these three entry points.

---

## Tab 1: Home

### Home Screen (default landing)

![Home Screen](/tmp/pyramid-sim-01-current.png)

**What the user sees:**
- **Countdown timer** — "GAMEWEEK BEGINS 2d 01h 41m" — counts down to next deadline
- **League selector** — horizontal scrolling pills: "Test v12", "Lsus", "Test", "Office Legends", etc. Tapping switches which league's data is shown below.
- **Pick card** — Large card area. Shows "No selection yet" with shield icon when no pick made. After picking: shows team badge, fixture details, and "CHANGE PICK" button.
- **"MAKE YOUR PICK" button** — Primary yellow CTA, navigates to Picks View
- **"1 of 1 players remaining"** — Active player count for selected league
- **"LAST WEEK'S RESULTS"** — Tap to see previous gameweek results

**After deadline (picks locked):**
- Pick card shows "LOCKED" pill instead of "CHANGE PICK"
- If match is live: score displayed, LIVE pulse dot, surviving/not indicator
- If match finished: "SURVIVED" (green) or "ELIMINATED" (red) pill

---

## Tab 1 → Picks View

### Carousel Mode (default)

**What the user sees:**
- Horizontal swipeable carousel of fixture cards
- Each card: home/away team badges, kickoff time, venue, broadcast info
- Two pick buttons (home team / away team) at bottom of card
- Greyed-out teams = already used this round (pill shows "Used GW{N}")
- Flip gesture or stats button → reveals H2H stats on card back
- Top: league name + gameweek label
- View mode toggle (carousel/list) in toolbar

### List Mode

**What the user sees:**
- Vertical scrollable list of fixtures
- Each row: home vs away, kickoff time, pick buttons inline
- More compact, faster to scan all fixtures
- Same team-used restrictions

### After Picking

- Confetti animation plays briefly
- Auto-dismisses back to Home
- Home now shows the pick card with team badge + fixture

---

## Tab 2: Leagues

### Leagues List

**What the user sees:**
- List of joined leagues as cards
- Each card: league name, emoji icon, member count, league status
- Active leagues have colored accent
- Completed leagues show winner info
- Toolbar menu (top right, "+" icon):
  - "Create League"
  - "Join with Code"
  - "Browse Free Leagues"

### Create League Sheet

**What the user sees:**
- League name text field
- Emoji identity picker (grid of emoji options)
- Free/Paid toggle
- If paid: stake amount field, player limit
- "Create League" button
- Success → League Created view with join code + share button

### Join League Sheet

**What the user sees:**
- Text field for join code
- "Join" button → preview of league (name, members, type)
- "Confirm Join" button
- If paid league: additional stake confirmation step with amount display

### Browse Free Leagues Sheet

**What the user sees:**
- Scrollable list of public free leagues
- Each row: league name, member count, spots remaining
- Tap to join directly
- Alert confirmation before joining

---

## Tab 2 → League Detail

### League Detail View

**What the user sees:**
- **Navigation title:** League name (large)
- **Toolbar icons:** Gear (admin), Clock (history), Share, Calendar (results), "My Pick" button
- **Stats header:** Active / Eliminated / Total member counts with colored badges
- **My Pick card:** Your current pick for this gameweek (or empty state)
- **"GW Recap" button:** Golden capsule pill (only visible when gameweek story exists)
- **"Reveal All Picks" button:** Green capsule pill (only visible after deadline)
- **Members list:** Sorted standings
  - Winner members (gold badge) at top
  - Active members (green badge)
  - Eliminated members (red badge) at bottom with "Eliminated GW{N}" label
  - Each row: avatar, display name, pick info
  - Before deadline: lock icon instead of pick
  - After deadline: team name, live score if applicable
  - After settlement: Survived/Eliminated result badge
- **Activity feed:** Recent events (picks made, eliminations, etc.)

### Pick Reveal Sheet (post-deadline)

**What the user sees:**
- Modal sheet with "Pick Reveal" title
- "Picks are in!" header
- 2-column grid of cards
- Each card starts face-down (avatar + name + lock icon)
- Cards flip one by one (0.12s stagger) to reveal team badge + team name
- Member name shown below each revealed card
- "Done" button to dismiss

### Gameweek Story (full screen)

**What the user sees:**
- Full-screen immersive story experience (like Instagram Stories)
- Tap/swipe to advance through cards:
  1. **Title card** — "Gameweek {N}" with dramatic styling
  2. **Headline card** — Key result of the gameweek
  3. **Your pick card** — What you picked, survived or eliminated
  4. **Upset cards** — Surprise results that caught people out
  5. **Elimination cards** — Who got knocked out and how
  6. **Mass elimination card** — If many players eliminated at once
  7. **Wildcard card** — Unusual events
  8. **Standing card** — League table snapshot
- "View Overview" button at end

### Gameweek Overview (full screen)

**What the user sees:**
- Summary stats for the gameweek
- Top picks section (most-chosen teams)
- "Replay Story" button
- "Done" button

### Pick History

**What the user sees:**
- List of all past gameweeks
- Each row: gameweek number, your pick, result (survived/eliminated/void)
- Scrollable history going back to GW1

### Results View

**What the user sees:**
- Gameweek selector at top
- All fixtures for selected gameweek with scores
- Your pick highlighted
- FT/Live status on each fixture

### Edit League (admin only)

**What the user sees:**
- League name field
- Emoji picker
- Settings toggles
- "Save" button

### League Complete Sheet

**What the user sees:**
- Winner announcement with confetti/celebration
- Winner avatar + name
- Final standings summary
- Prize split info (paid leagues: 65% / 25% / 10%)

---

## Tab 3: Profile

### Profile View

**What the user sees:**
- **Profile header:** Avatar, display name, username
- **Stats cards:** Survival streak, total wins, survival rate (3-column layout)
- **Achievement badges:** Grid of earned badges (tap for detail)
- **Settings rows:**
  - Leaderboard → Global rankings
  - Achievements → Full badge catalog
  - Notifications → Preference toggles
- **[DEBUG ONLY]:**
  - Design System Browser link
  - Gameweek phase picker
  - "Gameweek Recap" test button
  - "Reset Game Data" / "Reset Everything" buttons
- **Sign Out** button at bottom

### Leaderboard View

**What the user sees:**
- Global ranking table
- Each row: rank number, avatar, display name, stats (wins, streak)
- Your position highlighted

### Achievements View

**What the user sees:**
- Grid of all achievement badges
- Earned badges: full color with checkmark
- Unearned badges: greyed out with lock
- Tap badge → detail sheet with description + progress

### Notification Preferences

**What the user sees:**
- Toggle switches for:
  - Deadline reminders
  - Match results
  - League activity
  - Elimination alerts

---

## Auth Screen

### Login / Sign Up

**What the user sees:**
- App logo + name
- Email field + password field
- "Sign In" / "Sign Up" toggle
- "Sign in with Apple" button (native)
- "Sign in with Google" button (with Google logo)
- Error messages inline

---

## Onboarding

### Onboarding Pages (3 slides)

**What the user sees:**
- Paginated horizontal swipe
- Each page: illustration + title + description
- Page indicators (dots)
- "Get Started" button on final page

---

## Not Reachable (Orphaned Screens)

### Wallet View (not wired up)

**What exists in code but user cannot reach:**
- Balance display
- Transaction history list
- "Top Up" button → Top Up sheet (amount selection)
- "Withdraw" button → Withdraw sheet (bank details + amount)
- This needs to be connected before paid leagues are usable

---

## Screen Count Summary

| Category | Count |
|----------|-------|
| Tab screens | 3 (Home, Leagues, Profile) |
| Primary feature screens | 10 (Picks, League Detail, Story, etc.) |
| Modal/sheet screens | 12 (Create, Join, Edit, Reveal, etc.) |
| Settings screens | 3 (Leaderboard, Achievements, Notifications) |
| Auth screens | 2 (Auth, Onboarding) |
| Dev-only screens | 3 (DS Browser, Token Browser, Component Browser) |
| Orphaned screens | 1 (Wallet) |
| **Total** | **34** |
