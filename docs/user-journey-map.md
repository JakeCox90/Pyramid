# User Journey Map

> Every screen the user sees, from first launch to elimination. This is the single source of truth for "what does the user experience?"

Last updated: 2026-03-25

---

## Journey 1: First-Time User (Cold Start)

```
App Launch
    |
    v
[Loading Screen] --- error --> [Error + "Try Again"]
    |
    v (no session)
[Auth Screen]
    |-- Email sign-up --> enter email/password --> verify --> session created
    |-- Apple Sign-In --> native flow --> session created
    |-- Google Sign-In --> OAuth flow --> session created
    |
    v (session exists, first time)
[Onboarding] (3 paginated slides)
    |-- swipe through --> "Get Started"
    |
    v
[Main Tab View] --- lands on Home tab
```

**Key moments:** Auth is the only gate. Onboarding shows once. After that, the user lands on Home every time.

---

## Journey 2: Core Game Loop (Weekly Cycle)

This is the heartbeat of the app. Every gameweek follows this pattern:

```
BEFORE DEADLINE (countdown active)
================================

[Home Tab]
    |-- Shows: countdown timer, selected league, "No selection yet" card
    |-- "MAKE YOUR PICK" button --> [Picks View]
    |
    v
[Picks View] (carousel or list mode, persisted preference)
    |-- Browse fixtures for the gameweek
    |-- Each fixture shows: home/away teams, kickoff, badges
    |-- Greyed-out teams = already used in this round
    |-- Tap team to pick --> confirmation --> pick locked
    |-- Flip card for stats (carousel mode)
    |
    v (pick confirmed)
[Confetti Animation] --> auto-dismiss back to Home
    |
    v
[Home Tab] (updated)
    |-- Shows: your pick card (team badge + fixture details)
    |-- "CHANGE PICK" button visible until deadline
    |-- "1 of N players remaining"


AFTER DEADLINE (first kick-off)
===============================

[Home Tab]
    |-- Pick card shows LOCKED state
    |-- Live scores update via polling (every 60s)
    |-- Match card shows: score, LIVE pill, surviving/not indicator
    |
    v (navigate to league)
[League Detail View]
    |-- Standings show all members with their picks (now visible)
    |-- "Reveal All Picks" button --> [Pick Reveal Sheet]
    |       |-- Staggered card-flip animation
    |       |-- Each card: avatar (locked) flips to team badge
    |       |-- "Done" to dismiss
    |-- Live scores on each member row
    |-- LIVE pulse dot on active fixtures
    |
    v (all matches finish)
[League Detail View] (post-settlement)
    |-- Each member shows: Survived / Eliminated badge
    |-- Eliminated members sorted to bottom
    |-- "GW Recap" button --> [Gameweek Story]
            |-- Full-screen story cards (swipe through):
            |   1. Title card (gameweek number)
            |   2. Headline card (key result)
            |   3. Your pick card (survived/eliminated)
            |   4. Upset cards (surprise results)
            |   5. Elimination cards (who went out)
            |   6. Mass elimination card (if many eliminated)
            |   7. Wildcard card (unusual events)
            |   8. Standing card (league table snapshot)
            |-- "View Overview" --> [Gameweek Overview]
            |       |-- Summary stats + top picks
            |       |-- "Replay Story" or "Done"
```

**Key moments:**
- Pick selection is the primary action — everything leads to/from it
- Deadline is the tension point — picks hidden before, revealed after
- Settlement is passive — user watches scores, results are automatic
- Story recap is the emotional payoff after settlement

---

## Journey 3: League Management

```
[Leagues Tab]
    |-- Lists all joined leagues (cards with name, members, status)
    |-- Toolbar menu (top right):
    |       |-- "Create League" --> [Create League Sheet]
    |       |       |-- Name, emoji picker, free/paid toggle
    |       |       |-- "Create" --> [League Created View]
    |       |       |       |-- Join code displayed
    |       |       |       |-- Share button
    |       |
    |       |-- "Join with Code" --> [Join League Sheet]
    |       |       |-- Enter code --> preview league --> confirm join
    |       |       |-- (Paid leagues: [Join Paid League View] with stake confirmation)
    |       |
    |       |-- "Browse Free Leagues" --> [Browse Leagues Sheet]
    |               |-- List of public leagues
    |               |-- Tap to join
    |
    |-- Tap league card -->
    v
[League Detail View]
    |-- Stats header: active/eliminated/total counts
    |-- My Pick card (current gameweek)
    |-- Members list (standings)
    |-- Activity feed (recent events)
    |-- Toolbar:
    |       |-- [Gear icon] --> [Edit League] (admin only)
    |       |-- [Clock icon] --> [Pick History] (all gameweeks)
    |       |-- [Share icon] --> Share sheet (join code)
    |       |-- [Calendar icon] --> [Results View] (by gameweek)
    |       |-- "My Pick" button --> [Picks View]
    |
    |-- When league completes:
    v
[League Complete Sheet]
    |-- Winner announcement
    |-- Final standings
```

---

## Journey 4: Profile & Settings

```
[Profile Tab]
    |-- Profile stats: survival streak, total wins, survival rate
    |-- Achievements section (badge grid)
    |       |-- Tap badge --> [Achievement Detail Sheet]
    |
    |-- Settings:
    |       |-- "Leaderboard" --> [Leaderboard View]
    |       |       |-- Global ranking table
    |       |-- "Achievements" --> [Achievements View]
    |       |       |-- Full badge catalog
    |       |-- "Notifications" --> [Notification Preferences]
    |               |-- Toggle: deadline reminders, results, league activity
    |
    |-- [DEBUG ONLY]:
    |       |-- "Design System" --> [Design System Browser]
    |       |-- Gameweek phase picker
    |       |-- "Gameweek Recap" --> [Story View] (test mode)
    |       |-- "Reset Game Data" / "Reset Everything"
    |
    |-- "Sign Out" button --> [Auth Screen]
```

---

## Journey 5: Elimination & End-of-Round

```
[Settlement happens server-side after all FT results]
    |
    v (user opens app)
[Home Tab]
    |-- Pick card shows: "ELIMINATED" or "SURVIVED" pill
    |-- If eliminated: card shows red state
    |-- If survived: card shows green state
    |
    v (navigate to league)
[League Detail View]
    |-- Eliminated members shown with red badge, sorted to bottom
    |-- "Eliminated GW{N}" label on each
    |
    v (if all rounds complete OR one player left)
[League Complete Sheet] (auto-shows)
    |-- Winner(s) announced
    |-- Prize split displayed (paid leagues: 65/25/10)
```

---

## Screen Inventory (by reachability)

### Always Reachable (3 tabs)
| Screen | Tab | Purpose |
|--------|-----|---------|
| Home | Home | Dashboard: countdown, pick card, players remaining |
| Leagues List | Leagues | All joined leagues |
| Profile | Profile | Stats, achievements, settings |

### One Tap from Tabs
| Screen | From | Trigger |
|--------|------|---------|
| League Detail | Leagues tab | Tap league card |
| Picks View | Home / League Detail | "Make Your Pick" / "My Pick" |
| Leaderboard | Profile | Settings row |
| Achievements | Profile | Settings row |
| Notification Prefs | Profile | Settings row |

### Two+ Taps Deep
| Screen | From | Trigger |
|--------|------|---------|
| Pick Reveal | League Detail | "Reveal All Picks" (post-deadline only) |
| Gameweek Story | League Detail | "GW Recap" (post-settlement only) |
| Gameweek Overview | Gameweek Story | "View Overview" |
| Pick History | League Detail | Toolbar clock icon |
| Results View | League Detail | Toolbar calendar icon |
| Edit League | League Detail | Toolbar gear (admin only) |
| Create League | Leagues tab | Toolbar menu |
| Join League | Leagues tab | Toolbar menu |
| Browse Leagues | Leagues tab | Toolbar menu |
| Join Paid League | Join League | When league is paid |
| League Created | Create League | After creation |
| League Complete | League Detail | Auto-shows when league ends |

### Not Reachable in Normal Flow
| Screen | Notes |
|--------|-------|
| Wallet View | Built but not wired into navigation. No tab or link points here. |
| Design System Browser | Debug-only, not in release builds |
| Dev Reset Tools | Debug-only section in Profile |

---

## Timing & Conditional Gates

| Gate | What's Hidden | What's Shown |
|------|--------------|-------------|
| Before deadline | Other members' picks (locked icons) | Your pick card, "CHANGE PICK" button |
| After deadline | "CHANGE PICK" button | All picks visible, "Reveal All Picks" button, live scores |
| After settlement | Live score polling | Survived/Eliminated badges, "GW Recap" button |
| League complete | "My Pick" button | League Complete sheet, winner banner |
| Admin only | — | Edit League gear icon |
| Paid league | — | Stake confirmation in join flow |

---

## Known Gaps

1. **Wallet is orphaned** — WalletView exists with TopUp/Withdraw sheets but has no navigation path. Needs to be wired into Profile or a dedicated tab before paid leagues launch.
2. **No "what happens after elimination" flow** — Eliminated users see their status but there's no guidance on what they can do (spectate? join new league?). The app just shows them as eliminated in the standings.
3. **Story availability unclear to users** — "GW Recap" button only appears when `currentGameweek != nil` but there's no empty state explaining why it's not there.
4. **Pick change flow is the same as initial pick** — No dedicated "change pick" experience. User just re-enters the full Picks View, which could be confusing.
5. **No push notification → screen mapping** — Deep links route to tabs but not to specific leagues or picks.
