# Analytics Strategy Proposal — PYR-190

> **Status:** Proposal — awaiting human review and provider decision.
> This document presents options and recommendations. No implementation until approved.

---

## 1. Provider Recommendation

### Option A: TelemetryDeck (Recommended)

| Factor | Details |
|--------|---------|
| **Privacy** | Privacy-focused design with no direct identifiers by default; vendor positions the product as GDPR-friendly. Actual GDPR compliance, consent/notice requirements, and ATT prompt obligations depend on our specific implementation and jurisdictions and must be confirmed by legal/privacy review before launch. |
| **iOS SDK** | Native Swift SDK, lightweight (~200KB), SwiftUI lifecycle hooks |
| **Cost** | Free tier: 100K signals/month. Pro: €9/month for 1M signals. |
| **Server-side** | REST API for Edge Function events |
| **Dashboards** | Built-in funnels, retention cohorts, and custom queries |
| **Supabase** | No native integration, but REST API works from Edge Functions |

**Why:** For a launch-phase app with <1K users, TelemetryDeck likely reduces some GDPR consent and ATT complexity compared with more invasive analytics, while still giving us funnels and retention. Final decisions on consent banners, privacy notices, and ATT prompts must be made by legal/privacy stakeholders before implementation. The Swift SDK is purpose-built for iOS. Upgrade path to PostHog if we outgrow it.

### Option B: PostHog (Cloud)

| Factor | Details |
|--------|---------|
| **Privacy** | Configurable — can anonymise, but requires consent flow for EU |
| **iOS SDK** | Mature iOS SDK, autocapture available |
| **Cost** | Free tier: 1M events/month. Generous for launch. |
| **Server-side** | Full API, official Deno/Node SDK |
| **Dashboards** | Excellent — funnels, cohorts, feature flags, session replay |
| **Supabase** | Community integration exists |

**Why not first choice:** Requires GDPR consent flow implementation, ATT prompt strategy. More powerful but more implementation overhead for launch.

### Option C: Mixpanel / Amplitude

**Not recommended for launch.** Both are powerful but expensive at scale, require consent flows, and have heavier SDKs. Better suited for post-launch when we have product-market fit and can justify the cost.

### Option D: Firebase Analytics

**Not recommended.** Google ecosystem lock-in, less privacy-friendly, weaker funnel analysis. We already use Supabase (not Firebase) for auth and DB, so no synergy.

---

## 2. Event Taxonomy

### Naming Convention

```
{noun}_{verb}
```

Examples: `pick_submitted`, `league_created`, `recap_viewed`

All events include default properties:
- `app_version` — iOS build version
- `platform` — always `ios` for now
- `user_id` — anonymised hash (TelemetryDeck) or Supabase user ID (PostHog)

### V1 Events (Launch — Critical)

These are the minimum events needed to measure product health.

#### Client-side (iOS)

| Event | Properties | Why |
|-------|-----------|-----|
| `app_opened` | `source: cold/warm` | DAU/MAU, session frequency |
| `screen_viewed` | `screen_name` | Navigation patterns |
| `pick_screen_opened` | `league_id` | Top of pick funnel |
| `pick_team_selected` | `league_id, team_id` | Mid-funnel |
| `pick_submitted` | `league_id, gameweek_id` | Bottom of funnel — core action |
| `pick_changed` | `league_id, gameweek_id` | Indecision signal |
| `league_created` | `type: free/paid` | Growth metric |
| `league_joined` | `type: free/paid, method: code/browse` | Growth metric |
| `league_left` | `league_id` | Churn signal |
| `recap_viewed` | `league_id, gameweek_id` | Engagement metric |
| `share_tapped` | `league_id` | Viral loop |

#### Server-side (Edge Functions)

| Event | Properties | Source Function | Why |
|-------|-----------|-----------------|-----|
| `pick_confirmed` | `league_id, gameweek_id, team_id` | `submit-pick` | Source-of-truth pick rate (not client-reported) |
| `settlement_completed` | `gameweek_id, survived, eliminated` | `settle-picks` | Game health |
| `wallet_topup` | `amount` | `top-up` | Revenue metric |
| `wallet_withdrawal` | `amount` | `request-withdrawal` | Cash-out rate |
| `paid_league_joined` | `league_id, stake` | `join-paid-league` | Revenue metric |

### V2 Events (Post-Launch)

| Event | Why |
|-------|-----|
| `notification_opened` | Push notification effectiveness |
| `deadline_reminder_viewed` | Deadline anxiety feature value |
| `h2h_stats_viewed` | Feature adoption |
| `achievement_earned` | Engagement depth |
| `spectator_browse_leagues` | Re-engagement funnel |
| `story_slide_viewed` | Recap engagement depth |

### V3 Events (Growth Phase)

| Event | Why |
|-------|-----|
| `onboarding_step_completed` | Onboarding funnel |
| `referral_link_shared` | Viral coefficient |
| `search_performed` | Discovery UX |
| `error_displayed` | Error rate monitoring |

---

## 3. Implementation Architecture

### Client-side (iOS)

```
PyramidApp.swift
  └── AnalyticsService (singleton)
        ├── track(_ event: AnalyticsEvent)
        ├── identify(userId: String)  // anonymised
        └── flush()

AnalyticsEvent (enum)
  ├── .appOpened(source: AppSource)
  ├── .screenViewed(name: String)
  ├── .pickSubmitted(leagueId: UUID, gameweekId: Int)
  └── ... (one case per event)
```

Benefits of enum-based events:
- Compile-time safety — typos impossible
- Properties are type-checked
- Easy to audit which events exist

### Server-side (Edge Functions)

```
_shared/analytics.ts
  ├── trackEvent(name: string, properties: Record<string, unknown>)
  └── // Sends to TelemetryDeck/PostHog REST API
       // Best-effort await with short timeout (~500ms)
```

Called from Edge Functions after the primary operation succeeds. Each analytics call is awaited with a short timeout (500ms) wrapped in a `try/catch` — this ensures the Deno runtime doesn't drop the outbound request when the function returns, while keeping latency impact minimal. Analytics failures are logged but never cause user-facing errors or retries.

### Privacy Implementation

#### If TelemetryDeck (Recommended)
- TelemetryDeck doesn't use IDFA, so ATT prompt is likely not required — confirm with legal review
- User ID is a SHA-256 hash of Supabase user ID (one-way, non-reversible). Note: hashed user IDs are pseudonymous personal data under GDPR — privacy notice and legal basis still required even without direct PII
- Consent banner may not be needed depending on jurisdiction and implementation — legal review required before launch
- App Privacy Nutrition Label: "Analytics — Not Linked to You"

#### If PostHog
- ATT prompt on second app open (not first — let user experience the app first)
- GDPR consent modal before any tracking for EU users
- Respect `ATTrackingManager.trackingAuthorizationStatus`
- Fallback to anonymous session tracking if denied

---

## 4. Key Dashboards

### Dashboard 1: Pick Submission Funnel
```
app_opened → pick_screen_opened → pick_team_selected → pick_submitted
```
Goal: >60% completion from pick_screen_opened to pick_submitted.

### Dashboard 2: Weekly Retention
```
Cohort: users who signed up in week N
D1, D7, D14, D30 return rates
```
Goal: >40% D7 retention.

### Dashboard 3: Match-Day Engagement
```
DAU on match days vs non-match days
Pick submissions by hour (relative to kickoff)
```
Insight: When do users engage? How close to deadline?

### Dashboard 4: League Health
```
Leagues created per week
Average members per league
% leagues reaching 5+ members (minimum for paid)
League completion rate (% that reach a winner)
```

### Dashboard 5: Revenue (Paid Leagues)
```
Wallet top-ups per week
Paid leagues joined per week
Average stake per league
Withdrawal rate (% of deposited funds withdrawn)
```

---

## 5. Implementation Phases

### Phase 1: Foundation (1-2 days)
- [ ] Integrate provider SDK in iOS app
- [ ] Create `AnalyticsService` with event enum
- [ ] Create `_shared/analytics.ts` for Edge Functions
- [ ] Track: `app_opened`, `screen_viewed`, `pick_submitted` (client + server)
- [ ] Verify events appear in provider dashboard

### Phase 2: Core Funnel (1 day)
- [ ] Add remaining V1 client events
- [ ] Add remaining V1 server events
- [ ] Configure pick submission funnel dashboard
- [ ] Configure weekly retention dashboard

### Phase 3: Dashboards & Alerts (1 day)
- [ ] Build all 5 dashboards listed above
- [ ] Set up alerts: pick rate drops >50%, DAU drops >30%
- [ ] Document dashboard access and alert ownership

---

## 6. Decision Required

Before implementation can begin, we need agreement on:

1. **Provider choice** — TelemetryDeck (recommended) or PostHog?
2. **V1 event list** — anything to add/remove from the list above?
3. **Privacy approach** — is the no-ATT approach (TelemetryDeck) acceptable, or do we need richer user-level data (PostHog)?

These are product decisions that affect user experience and data strategy. Flagging for human review.
