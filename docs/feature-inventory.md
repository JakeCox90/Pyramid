# Feature Inventory

> Matrix of what's built, what's wired up, and what's orphaned. Use this to understand the gap between "code exists" and "user can reach it."

Last updated: 2026-03-25

---

## Summary

| Metric | Count |
|--------|-------|
| Total Swift files | 189 |
| Feature screens (navigable views) | 33 |
| Reachable in normal flow | 28 |
| Orphaned (code exists, not reachable) | 2 |
| Dev-only (debug builds) | 16 |
| Services | 17 (all active) |
| Models | 20 (all active) |
| Design system components | 27 |

---

## Feature Status Matrix

### Core Game Loop

| Feature | Status | Wired Up? | Screen | Notes |
|---------|--------|-----------|--------|-------|
| Gameweek countdown | Built | Yes | Home | Live countdown to next deadline |
| League selector (Home) | Built | Yes | Home | Horizontal pill bar, switches context |
| Pick selection (carousel) | Built | Yes | Picks | Primary mode, card flip to stats |
| Pick selection (list) | Built | Yes | Picks | Alternative mode, persisted preference |
| Used team tracking | Built | Yes | Picks | Grey out teams already used this round |
| Pick confirmation + confetti | Built | Yes | Picks | Animation on successful pick |
| Pick change (before deadline) | Built | Yes | Home → Picks | "CHANGE PICK" button on match card |
| Pick locking (at deadline) | Built | Yes | Home/League | Card shows LOCKED state |
| Live score polling | Built | Yes | League Detail | 60s interval when fixtures are live |
| Pick reveal animation | Built | Yes | League Detail | Post-deadline, staggered card flip |
| Settlement display | Built | Yes | League Detail | Survived/Eliminated badges on members |
| Gameweek story/recap | Built | Yes | League Detail | Full-screen story cards, 8 card types |
| Gameweek overview | Built | Yes | Story → Overview | Stats summary after story |
| Pick history | Built | Yes | League Detail | All past gameweek picks |
| Results view | Built | Yes | League Detail | Historical results by gameweek |

### League Management

| Feature | Status | Wired Up? | Screen | Notes |
|---------|--------|-----------|--------|-------|
| League list | Built | Yes | Leagues tab | Cards with name, members, status |
| Create league (free) | Built | Yes | Leagues → Create | Name, emoji, settings |
| Create league (paid) | Built | Yes | Leagues → Create | Stake amount, player limits |
| Join with code | Built | Yes | Leagues → Join | Code entry → preview → confirm |
| Join paid league | Built | Yes | Join → Paid flow | Stake confirmation step |
| Browse free leagues | Built | Yes | Leagues → Browse | Public league discovery |
| League detail | Built | Yes | Leagues → Detail | Hub for all league activity |
| League standings | Built | Yes | League Detail | Sorted member list with status |
| League activity feed | Built | Yes | League Detail | Recent events (picks, eliminations) |
| Edit league (admin) | Built | Yes | League Detail | Admin-only gear icon |
| League share | Built | Yes | League Detail | Share join code via system sheet |
| League complete | Built | Yes | League Detail | Auto-shows winner announcement |
| League created feedback | Built | Yes | Create → Created | Shows join code after creation |

### Profile & Social

| Feature | Status | Wired Up? | Screen | Notes |
|---------|--------|-----------|--------|-------|
| Profile stats | Built | Yes | Profile | Survival streak, wins, rate |
| Achievements/badges | Built | Yes | Profile → Achievements | Badge catalog + detail sheet |
| Global leaderboard | Built | Yes | Profile → Leaderboard | Ranking table |
| Notification preferences | Built | Yes | Profile → Notifications | Toggle settings |
| Player avatars | Built | Yes | League Detail rows | Avatar + status badge on member rows |
| Sign out | Built | Yes | Profile | Bottom of settings |

### Authentication

| Feature | Status | Wired Up? | Screen | Notes |
|---------|--------|-----------|--------|-------|
| Email auth | Built | Yes | Auth | Sign up + sign in |
| Apple Sign-In | Built | Yes | Auth | Native flow |
| Google Sign-In | Built | Yes | Auth | OAuth flow |
| Onboarding | Built | Yes | Post-auth | 3 paginated slides, shows once |

### Payments & Wallet

| Feature | Status | Wired Up? | Screen | Notes |
|---------|--------|-----------|--------|-------|
| Wallet view | Built | **NO** | WalletView.swift | **ORPHANED** — no navigation path |
| Top-up sheet | Built | **NO** | WalletView+Sheets | Part of orphaned Wallet |
| Withdraw sheet | Built | **NO** | WalletView+Sheets | Part of orphaned Wallet |
| Paid league join | Built | Yes | Join flow | Stake confirmation works |
| Prize split display | Built | Yes | League Complete | 65/25/10 shown |

### Developer Tools

| Feature | Status | Wired Up? | Screen | Notes |
|---------|--------|-----------|--------|-------|
| Design system browser | Built | Debug only | Profile → DS Browser | Token + component viewer |
| Component browser (7 tabs) | Built | Debug only | DS Browser | Buttons, cards, inputs, flags, etc. |
| Token browser (6 tabs) | Built | Debug only | DS Browser | Colors, typography, spacing, etc. |
| Gameweek phase override | Built | Debug only | Profile | Phase picker dropdown |
| Dev story trigger | Built | Debug only | Profile | "Gameweek Recap" button |
| Reset game data | Built | Debug only | Profile | Clears picks/leagues |
| Reset everything | Built | Debug only | Profile | Full account reset |

---

## Architecture Health

### Services (all active, no orphans)

| Service | Used By | Purpose |
|---------|---------|---------|
| AuthService | AuthViewModel | Login/signup/session |
| HomeService | HomeViewModel | Gameweek data, fixtures |
| PickService | PicksViewModel, LeagueDetailVM | Pick CRUD, gameweek fetch |
| LeagueService | LeaguesViewModel, CreateLeagueVM, etc. | League CRUD |
| PaidLeagueService | JoinPaidLeagueVM | Paid league operations |
| StandingsService | LeagueDetailViewModel | Member standings + picks |
| AchievementService | AchievementsViewModel | Badge data |
| GameweekStoryService | GameweekStoryViewModel | Story card data |
| LeaderboardService | LeaderboardViewModel | Global rankings |
| ResultsService | ResultsViewModel | Historical results |
| WalletService | WalletViewModel | Balance + transactions |
| ActivityFeedService | LeagueDetailViewModel | League events |
| NotificationService | MainTabView | Deep link routing |
| NotificationPreferencesService | NotificationPrefsVM | Settings |
| ContentModerationService | CreateLeagueVM, EditLeagueVM | Text filtering |
| DevResetService | ProfileView | Debug data reset |

### Models (all active, no orphans)

Core models by reference count:
1. **Pick** — 460 references (most critical)
2. **League** — 460 references
3. **Gameweek** — 141 references
4. **Fixture** — 127 references
5. **LeagueMember** — 32 references
6. **GameweekStory/StoryCard** — 33 references
7. **ActivityEvent** — 17 references

### Design System

- **Theme.swift** — 1,684 references (foundation of all UI)
- **TeamBadge** — 59 references (most-used component)
- **Card** — used in every feature area
- 27 design system files total, all actively referenced

---

## Orphaned / Dead Code

| Item | Type | File | Notes |
|------|------|------|-------|
| WalletView | View | Features/Wallet/WalletView.swift | Built but never navigated to. Needs a home before paid leagues launch. |
| PicksHeaderView | View | Features/Picks/PicksHeaderView.swift | Duplicate of header logic already in PickCarouselView and PicksView. Safe to delete. |

---

## Feature Dependencies

```
Authentication
    └── required for everything below

Home Tab
    ├── depends on: LeagueService (league selector), HomeService (countdown), PickService
    └── navigates to: Picks View

Picks View
    ├── depends on: PickService, HomeService (fixtures)
    └── data: current gameweek, fixtures, used teams

League Detail
    ├── depends on: StandingsService, PickService, ActivityFeedService
    ├── navigates to: Picks, History, Results, Story, Pick Reveal, Edit, Complete
    └── polling: PickService.fetchFixtures (live scores)

Gameweek Story
    ├── depends on: GameweekStoryService (fetches from edge function)
    └── data: story cards generated server-side by generate-gameweek-story

Paid Leagues
    ├── depends on: PaidLeagueService, WalletService
    ├── WalletView is DISCONNECTED
    └── Join flow works but wallet management is not accessible

Achievements
    ├── depends on: AchievementService
    └── catalog defined in AchievementCatalog.swift (client-side)
```

---

## What's Missing (gaps in the user experience)

| Gap | Impact | Effort | Notes |
|-----|--------|--------|-------|
| Wallet not wired up | Users can't manage funds for paid leagues | Low | Just needs navigation link from Profile |
| No post-elimination guidance | Eliminated users don't know what to do next | Medium | Need "spectator mode" or "join new league" prompt |
| No empty state for Story | "GW Recap" button just doesn't appear if no story exists | Low | Add explanation text |
| Deep links go to tabs only | Push notifications can't route to specific league/pick | Medium | Need parameterised deep link handling |
| No pick change confirmation | Changing pick uses same flow as initial pick | Low | Could add "Are you sure?" or dedicated UI |
| PicksHeaderView is dead code | Confusing for developers | Trivial | Delete it |
