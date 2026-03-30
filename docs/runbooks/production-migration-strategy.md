# Production Migration & Launch Strategy

> Complete checklist for deploying Pyramid to production for the first time.
> Companion to [production-deployment.md](./production-deployment.md) which covers CI/CD mechanics.

---

## Prerequisites

Before starting, ensure:

- [ ] GitHub `production` Environment created with required reviewers (see production-deployment.md §1)
- [ ] All GitHub Secrets configured (see production-deployment.md §2)
- [ ] Supabase prod project (`cracvbokmvryhhclzxxw`) is active and accessible
- [ ] API-Football API key is valid and has sufficient quota
- [ ] GATE decisions resolved: PYR-26 (Compliance/UKGC/KYC), PYR-34 (Human sign-off)

---

## Phase 1: Migration Chain Verification

Verify all 19 migrations apply cleanly in order against a fresh database.

### 1.1 Local dry run (fresh database)

```bash
# Stop any running Supabase instance
supabase stop

# Start fresh — this applies all migrations in order to a clean local DB
supabase start

# Verify no errors in the output — every migration should show ✓
```

### 1.2 Verify migration order

Migrations must apply in lexicographic order. Confirm no dependency violations:

| # | Migration | Creates / Modifies | Depends On |
|---|-----------|-------------------|------------|
| 1 | `20260307000000_initial_schema` | profiles, gameweeks, fixtures, leagues, league_members, picks, used_teams (view), settlement_log | auth.users (built-in) |
| 2 | `20260308000000_notification_tables` | device_tokens, notification_preferences | profiles |
| 3 | `20260308100000_paid_league_columns` | leagues (add columns) | leagues |
| 4 | `20260308200000_prize_distribution_schema` | wallet_transactions (first attempt) | leagues, league_members |
| 5 | `20260308300000_wallet_tables` | wallet_transactions (IF NOT EXISTS) | profiles |
| 6 | `20260310000000_fix_league_members_rls` | league_members RLS policies | league_members |
| 7 | `20260311000000_fixture_logo_columns` | fixtures (add columns) | fixtures |
| 8 | `20260320000000_dev_reset_function` | dev_reset_data() function | all tables |
| 9 | `20260322000000_used_teams_round_number` | used_teams view (replace) | picks, fixtures, gameweeks |
| 10 | `20260323000000_global_leaderboard` | leaderboard tables/views | profiles, leagues |
| 11 | `20260323100000_user_stats` | user_stats view/function | profiles, picks, leagues |
| 12 | `20260323150000_gameweek_stories` | gameweek_stories table | gameweeks, leagues |
| 13 | `20260324000000_achievements` | achievements tables | profiles |
| 14 | `20260324100000_achievements_backfill` | backfill data | achievements |
| 15 | `20260324200000_league_identity` | leagues (add columns) | leagues |
| 16 | `20260324_used_teams_round_number` | used_teams view (replace) | picks, fixtures |
| 17 | `20260325000000_fixture_venue` | fixtures (add columns) | fixtures |
| 18 | `20260327100000_atomic_withdrawal` | withdrawal functions | wallet_transactions |
| 19 | `20260327110000_atomic_join_paid_league` | join-paid-league function | leagues, wallet_transactions |

### 1.3 Verify against prod (dry run)

```bash
# Via GitHub Actions:
# 1. Go to Actions → Deploy Migrations (Production)
# 2. Run with dry_run=true
# 3. Review the diff output — should show all 19 migrations as pending
```

---

## Phase 2: Reference Data Seeding

Production needs Premier League reference data before the app is usable. This data comes from API-Football, not from seed files.

### 2.1 Seed gameweeks and fixtures

After migrations are applied, run `sync-fixtures` to populate gameweeks and fixtures for the current season:

```bash
# Full season sync — creates all 38 gameweeks and their fixtures
curl -X POST https://cracvbokmvryhhclzxxw.supabase.co/functions/v1/sync-fixtures \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"season": 2025}'
```

This is idempotent — safe to run multiple times.

### 2.2 Seed odds data

```bash
# Sync odds for the next upcoming gameweek
curl -X POST https://cracvbokmvryhhclzxxw.supabase.co/functions/v1/sync-odds \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 2.3 Verify reference data

After seeding, confirm the data looks right:

```sql
-- Connect to prod DB via Supabase dashboard SQL Editor

-- Should return 38 gameweeks
SELECT count(*) FROM gameweeks;

-- Should return 380 fixtures (38 rounds × 10 matches)
SELECT count(*) FROM fixtures;

-- Spot-check: fixtures should have team names, kickoff times, and logos
SELECT id, home_team_name, away_team_name, kickoff_at, status
FROM fixtures
WHERE gameweek_id = (SELECT id FROM gameweeks ORDER BY id LIMIT 1)
LIMIT 5;

-- Verify no orphaned fixtures (every fixture belongs to a valid gameweek)
SELECT count(*) FROM fixtures f
LEFT JOIN gameweeks g ON f.gameweek_id = g.id
WHERE g.id IS NULL;
-- Expected: 0
```

### 2.4 What NOT to seed

- **Profiles** — created automatically via trigger when users sign up
- **Leagues** — created by users via the app
- **Picks** — submitted by users via the app
- **Wallet data** — created on first wallet interaction
- **Dev reset function** — exists in migrations but is gated by `app.environment = 'dev'`, so it's inert in prod

---

## Phase 3: RLS Policy Verification

Every table with user data must have RLS enabled. Verify no table is accidentally open.

### 3.1 Check RLS is enabled on all public tables

```sql
-- Run in Supabase SQL Editor against prod
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Expected:** Every row should show `rowsecurity = true`. If any table shows `false`, that's a critical security issue — do not launch.

### 3.2 List all RLS policies

```sql
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### 3.3 Verify key security properties

| Table | Expected Policies |
|-------|-------------------|
| profiles | SELECT: anyone; UPDATE: own row only |
| leagues | SELECT: members only (via league_members join); INSERT: via Edge Function |
| league_members | SELECT: same-league members only |
| picks | SELECT: own picks always, others' picks after deadline; INSERT/UPDATE: own only |
| settlement_log | SELECT: league members only; INSERT: service role only |
| wallet_transactions | SELECT: own transactions only |
| device_tokens | All ops: own rows only |
| notification_preferences | All ops: own rows only |

### 3.4 Test RLS with anon key

```bash
# This should return an empty array (anon can't read leagues)
curl https://cracvbokmvryhhclzxxw.supabase.co/rest/v1/leagues \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"

# This should return an empty array (anon can't read picks)
curl https://cracvbokmvryhhclzxxw.supabase.co/rest/v1/picks \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

---

## Phase 4: Edge Function Deployment Verification

After deploying Edge Functions via CI, verify each one is reachable.

### 4.1 Health check

```bash
curl -s https://cracvbokmvryhhclzxxw.supabase.co/functions/v1/health \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" | jq .
```

Expected: `status: "healthy"` or `"degraded"` (degraded is OK if no gameweek data yet).

### 4.2 Verify all functions are deployed

```bash
# Each should return 401 (Unauthorized) or 405 (Method Not Allowed), NOT 404
for fn in create-league join-league join-paid-league submit-pick get-wallet \
          top-up request-withdrawal update-league update-profile leave-league \
          register-device-token validate-league-content settle-picks \
          credit-winnings distribute-prizes refund-stake process-dispute-window \
          poll-live-scores sync-fixtures sync-odds get-head-to-head \
          generate-gameweek-story health reset-dev-data; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    https://cracvbokmvryhhclzxxw.supabase.co/functions/v1/$fn)
  echo "$fn: $STATUS"
done
```

**Expected:** Every function returns a status code (401, 405, etc.) — never 404. A 404 means the function wasn't deployed.

---

## Phase 5: End-to-End Smoke Test

Run through the core user journey manually to verify everything works together.

### 5.1 Pre-test setup

1. Sign up a test user via the iOS app (or Supabase Auth dashboard)
2. Verify profile was auto-created: `SELECT * FROM profiles WHERE id = '<user-id>';`

### 5.2 Core game loop

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Create a free league | 200 response, league appears in DB |
| 2 | Join the league with a second test user | 200 response, league_members row created |
| 3 | Submit a pick for the current gameweek | 200 response, pick row with `result: 'pending'` |
| 4 | Change the pick (before deadline) | 200 response, pick updated |
| 5 | Attempt to pick same team in next GW | 409 `TEAM_USED` error |
| 6 | Leave the league | 200 response, member status updated |

### 5.3 Wallet operations (paid leagues)

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Get wallet balance | 200 response, balance = 0 |
| 2 | Top up wallet | 200 response, balance increases |
| 3 | Join a paid league | 200 response, stake deducted atomically |
| 4 | Request withdrawal | 200 response, withdrawal recorded |

### 5.4 Service-role operations

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Trigger sync-fixtures | Gameweeks and fixtures populated |
| 2 | Trigger sync-odds | Odds data populated for upcoming fixtures |
| 3 | Trigger settle-picks (on completed GW) | Picks updated with results |
| 4 | Trigger credit-winnings | Winners credited |

---

## Phase 6: Rollback & Recovery

### 6.1 Migration rollback

Supabase migrations are **forward-only** — there is no `supabase db rollback`.

**If a migration breaks prod:**

1. **Assess damage** — is the DB usable? Can the app still function?
2. **Write a corrective migration** — a new migration that undoes the bad change
3. **Apply via CI** — use the normal deploy-migrations-prod workflow
4. **If DB is completely broken** — restore from Supabase's point-in-time recovery (Settings → Database → Backups)

**Prevention:**
- Always run `dry_run=true` first
- Review the diff output carefully
- Test locally with `supabase start` before deploying

### 6.2 Edge Function rollback

```bash
# Find the last known-good tag
git tag --list 'prod-functions-*' --sort=-creatordate | head -5

# Check out that tag and re-deploy
git checkout <tag>
# Trigger deploy-functions-prod workflow
```

### 6.3 Full rollback (nuclear option)

If everything is broken and you need to start fresh:

1. **Pause the app** — set a maintenance flag or take down Edge Functions
2. **Restore DB from backup** — Supabase Dashboard → Settings → Database → Backups → Point-in-time recovery
3. **Re-deploy Edge Functions** from the last known-good tag
4. **Re-seed reference data** — run sync-fixtures and sync-odds again
5. **Verify** — run the smoke test suite from Phase 5

---

## Deployment Order Checklist

Execute in this exact order:

- [ ] **1. Verify migrations locally** — `supabase stop && supabase start` (Phase 1.1)
- [ ] **2. Deploy migrations to prod** — dry run first, then apply (Phase 1.3)
- [ ] **3. Verify RLS policies** — run SQL checks (Phase 3)
- [ ] **4. Deploy Edge Functions** — via deploy-functions-prod workflow (Phase 4)
- [ ] **5. Verify all functions reachable** — run curl loop (Phase 4.2)
- [ ] **6. Seed reference data** — sync-fixtures, then sync-odds (Phase 2)
- [ ] **7. Run health check** — verify all components healthy (Phase 4.1)
- [ ] **8. Smoke test** — full game loop end-to-end (Phase 5)
- [ ] **9. Deploy iOS to TestFlight** — only after backend is verified
- [ ] **10. Monitor** — watch health endpoint and error logs for 24 hours

---

## Post-Launch Monitoring

- **Health endpoint**: `https://cracvbokmvryhhclzxxw.supabase.co/functions/v1/health` — see [health-monitoring.md](./health-monitoring.md) for setup
- **Supabase Dashboard**: Edge Function logs, DB metrics, Auth user count
- **API-Football quota**: Checked by health endpoint (warns at >80% daily usage)
- **Settlement monitoring**: Health endpoint warns if FT results are unsettled for >6 hours
