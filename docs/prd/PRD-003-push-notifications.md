# PRD-003: Push Notifications

**Status:** Draft
**Date:** 2026-03-07
**Author:** Orchestrator
**Linear:** PYR-24
**Phase:** 2
**Rules reference:** docs/game-rules/rules.md §3.2, §3.3, §4.4

---

## Goal

Players receive timely push notifications for pick deadlines, match results, and league events so they never miss a submission or outcome.

---

## Notification Events

### Pick Deadline Reminder
- **Trigger:** 1 hour before the first match of each gameweek (the pick deadline)
- **Recipients:** All active members in any league who have not yet submitted a pick for that GW
- **Message:** "Deadline in 1 hour — pick your team for GW{N} before kick-off"
- **Deep link:** Opens Picks screen for the relevant league

### Pick Locked
- **Trigger:** When the player's chosen match kicks off (pick locked)
- **Recipients:** The individual player whose pick just locked
- **Message:** "{Team Name} vs {Opponent} has kicked off — your pick is locked. Good luck!"
- **Deep link:** Opens League standings for that league

### Result Alert
- **Trigger:** When `settle-picks` processes a result for a player's pick
- **Recipients:** The individual player
- **Message (survived):** "Full time: {Team} {score} — you survived GW{N}!"
- **Message (eliminated):** "Full time: {Team} {score} — you've been eliminated from {League Name}"
- **Message (void):** "{Team}'s match was postponed — your pick is voided. Repick now."
- **Deep link:** Opens League standings

### Mass Elimination
- **Trigger:** When a mass elimination event occurs in a league
- **Recipients:** All reinstated members
- **Message:** "Mass elimination in {League Name} — everyone survives! GW{N} picks count as used."
- **Deep link:** Opens League standings

### Round Complete (Paid Leagues)
- **Trigger:** When `distribute-prizes` completes for a league
- **Recipients (winner):** "You won £{amount} in {League Name}! Your winnings are available to play."
- **Recipients (placed):** "Round over — you finished {position} in {League Name} and won £{amount}."
- **Recipients (no prize):** "Round over in {League Name} — well played. Join a new round?"
- **Deep link:** Opens Wallet (winners) or League result screen (all)

### Winnings Withdrawable
- **Trigger:** 24-hour dispute window expires, funds move to Withdrawable
- **Recipients:** User with newly withdrawable funds
- **Message:** "£{amount} is now available to withdraw from your wallet."
- **Deep link:** Opens Wallet screen

---

## Acceptance Criteria

### iOS
- [ ] APNs registration at app launch — request permission on first paid league join (not on install)
- [ ] Permission prompt explains value: "Get notified before pick deadlines and when results are in"
- [ ] Notification settings screen: user can enable/disable each notification category independently
- [ ] Notifications honour iOS Do Not Disturb
- [ ] Deep links route correctly from notification tap

### Backend
- [ ] `device_tokens` table: stores APNs tokens per user (one user can have multiple devices)
- [ ] `send-notification` shared Edge Function: accepts userId, templateId, data — looks up tokens and sends via APNs
- [ ] `poll-live-scores` calls `send-notification` for pick-locked and result-alert events
- [ ] Supabase scheduled function sends deadline reminders 1 hour before first GW kick-off
- [ ] Notifications are fire-and-forget — failure does not block settlement
- [ ] Tokens automatically cleaned up on APNs 410 (device unregistered) response

---

## Data Model

### `device_tokens` table
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users |
| token | text | APNs device token |
| platform | enum | ios (only platform for now) |
| created_at | timestamptz | |
| last_seen_at | timestamptz | Updated on each successful delivery |

### `notification_preferences` table
| Column | Type | Notes |
|---|---|---|
| user_id | uuid | PK |
| deadline_reminders | boolean | Default true |
| pick_locked | boolean | Default true |
| result_alerts | boolean | Default true |
| winnings_alerts | boolean | Default true |

---

## Notification Provider

APNs direct — no third-party notification service. Supabase Edge Functions send directly to APNs HTTP/2 API using the app's APNs auth key. This avoids additional vendor dependency at current scale.

ADR not required — this is a straightforward implementation choice within existing stack.

---

## Out of Scope (Phase 2)
- Email notifications
- SMS notifications
- Android (iOS only)
- In-app notification centre / inbox

---

## Agent Instructions

**Backend Agent:** Implement `register-device-token` Edge Function (called on iOS app launch after permission granted). Implement `send-notification` shared utility in `_shared/`. Integrate notification sends into `poll-live-scores` and `settle-picks`. Notifications must not block or fail settlement — wrap all notification calls in try/catch.

**iOS Agent:** Request APNs permission at first paid league join attempt (not on app launch). Pass token to `register-device-token` Edge Function. Implement `NotificationService` singleton. Handle deep links from notification payload `screen` field.
