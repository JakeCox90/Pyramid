# ADR-003: Premier League Data Provider Choice

**Status:** Proposed — Pending GATE 0 approval
**Date:** 2026-03-07
**Deciders:** Architect Agent, Orchestrator
**Approver:** Human owner (GATE 0)
**Linear:** PYR-10 / LMS-006

---

## Context

Pyramid requires reliable, accurate Premier League data including:
- Season fixture list (all 380 matches, dates, kickoff times, venue)
- Live and final match results (home score, away score)
- Match status (scheduled, in progress, finished, postponed, abandoned)
- Gameweek structure (rounds 1–38)
- Team information (names, short codes, crests)

This data drives the entire pick and settlement engine. Incorrect or delayed results will cause incorrect eliminations — a critical trust and financial risk. Data must be:
- Available via API (polled or webhook)
- Accurate within minutes of final whistle
- Historically reliable across a full PL season
- Affordable at our scale

---

## Options Considered

### Option A: API-Football (Recommended)

**Provider:** RapidAPI / API-Sports
**Coverage:** Premier League (and all major competitions)

**Data quality:**
- Results typically updated within 1–2 minutes of full time
- Fixture list available at season start with gameweek round numbers
- Match status fields: `NS` (not started), `1H`, `HT`, `2H`, `FT`, `PST` (postponed), `CANC` (cancelled), `ABD` (abandoned)
- Team IDs are stable across seasons
- Covers VAR overturns in final result (result reflects official score)

**API design:**
- REST API, JSON responses
- Authentication via `X-RapidAPI-Key` header
- Rate limits: 100 requests/day (free), 500/day (Basic ~£8/month), unlimited (Pro ~£30/month)
- Endpoints needed: `/fixtures` (by league + season + round), `/fixtures?id=` (single match)

**Estimated cost:** £8–30/month depending on polling frequency
> If cost exceeds £50/month at scale: escalate to human (GATE required)

**Strengths:**
- Used widely in production football apps
- Good documentation
- Comprehensive status codes including postponed/abandoned
- Historical data available for testing
- Webhook support on higher tiers (reduces polling)

**Weaknesses:**
- RapidAPI dependency — if RapidAPI changes pricing, this is affected
- Free tier rate limits require careful polling strategy
- No official PL data licence — data is aggregated, not sourced direct from PL

---

### Option B: SportMonks

**Provider:** SportMonks B.V.

**Strengths:**
- Higher data quality on some metrics
- Official data partnerships
- Good webhook support

**Weaknesses:**
- Significantly more expensive (~€49–299/month)
- More complex API with many optional includes
- Overkill for a single-league Last Man Standing app
- API-Football is sufficient for our use case

---

### Option C: StatsBomb

**What it is:** High-quality event-level football data provider.

**Strengths:**
- Extremely detailed event data (passes, shots, xG)
- Used by professional clubs and analysts

**Weaknesses:**
- Designed for deep analytics, not live score/fixture APIs
- Expensive and requires direct commercial agreement
- Completely wrong tool for this use case — we need results, not event data

---

## Decision

**Recommended: API-Football**

API-Football provides accurate, timely Premier League results at a cost well within our budget. The status codes cover postponements and abandonments, which our settlement engine must handle. The free tier is sufficient for development and testing; the Basic tier (~£8/month) handles production polling.

StatsBomb is wrong for this use case. SportMonks is unnecessarily expensive.

---

## Integration Architecture

```
Scheduled Edge Function (every 2 min during live matches)
  → GET /fixtures?league=39&season=2025&round={current}
  → Compare result against DB
  → If result changed: update fixtures table, trigger settlement check
  → Settlement Edge Function processes any newly finished matches
```

- League ID for Premier League: `39`
- Season: `2025` (2025/26 season)
- Polling frequency: every 2 minutes during match windows; every 60 minutes otherwise
- All API calls made server-side (Edge Function) — API key never exposed to iOS client
- Raw API response stored in `fixture_results_raw` table for audit trail

---

## Settlement Safety Rules

These rules protect against incorrect eliminations from data issues:

1. **Never settle on non-FT status.** Only `FT` (full time) triggers settlement. `1H`, `HT`, `2H`, `ET`, `PEN` never trigger.
2. **Postponed matches (`PST`):** The pick is void for that gameweek. Players who picked the postponed team get a free pick for the rescheduled fixture's gameweek (GATE — exact rule requires human approval in game rules spec).
3. **Abandoned matches (`ABD`):** Treat as void. Same as postponed. Escalate to human if mid-settlement.
4. **API data discrepancy:** If two consecutive polls return different FT scores, hold settlement and alert Orchestrator. Never settle on ambiguous data.
5. **Idempotency:** Settlement Edge Function must be safe to run multiple times on the same fixture without double-processing. Use `settled_at` timestamp + idempotency key.

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| API-Football result delay > 5 minutes | Low | Medium | Poll every 2 min; alert if match is FT but score unchanged after 10 min |
| RapidAPI pricing change | Low | Medium | Monitor monthly; escalate if > £50/month |
| Incorrect score returned (API error) | Very Low | High | Hold settlement if consecutive polls disagree; human review before proceeding |
| Postponed match mid-gameweek | Medium | Medium | Handle PST status explicitly; game rules spec defines pick void policy |
| Rate limit breach on free tier | Medium | Low | Implement polling scheduler with backoff; upgrade to Basic tier for production |

---

## References

- [API-Football documentation](https://www.api-football.com/documentation-v3)
- docs/game-rules/rules.md — defines how postponed/abandoned matches affect picks
- ADR-001 (Supabase) — settlement Edge Functions run on Supabase
- LMS-008 (PYR-12) — API-Football account setup and fixture validation task
