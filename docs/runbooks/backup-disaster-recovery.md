# Database Backup & Disaster Recovery Plan

> Backup strategy, recovery objectives, and step-by-step recovery procedures for Pyramid's production database.
> This is a real-money gaming app — data loss of picks, wallet balances, or settlement results is catastrophic.

---

## Recovery Objectives

| Metric | Target | Rationale |
|--------|--------|-----------|
| **RPO** (Recovery Point Objective) | **≤ 5 minutes** | Supabase Pro plan provides PITR with WAL archiving. Max 5 min of data loss. Wallet transactions and settlement results are the most critical — any loss could mean financial discrepancies. |
| **RTO** (Recovery Time Objective) | **≤ 30 minutes** | Time from incident detection to service restoration. Supabase PITR restore takes ~10-15 min; remaining time for Edge Function verification and smoke testing. |

---

## Backup Layers

### Layer 1: Supabase Managed Backups (Primary)

Supabase provides automatic backups depending on plan tier:

| Plan | Backup Type | Frequency | Retention | PITR |
|------|------------|-----------|-----------|------|
| Free | Daily snapshot | Every 24h | 7 days | No |
| Pro | Daily snapshot + PITR | Continuous WAL | 7 days | Yes (to the second) |
| Team | Daily snapshot + PITR | Continuous WAL | 30 days | Yes |

**Action required before launch:**
- [ ] Confirm the prod project (`cracvbokmvryhhclzxxw`) is on the **Pro plan** (minimum) for PITR support
- [ ] Verify PITR is enabled: Supabase Dashboard → Settings → Database → Backups → Point-in-Time Recovery

### Layer 2: Logical Backups (Belt-and-Suspenders)

For critical financial tables, maintain a secondary backup via scheduled `pg_dump` of key tables. This protects against Supabase platform-level failures (rare but non-zero risk).

**Critical tables to export:**

| Table | Why Critical | Idempotency Key |
|-------|-------------|-----------------|
| `wallet_transactions` | Real money — every penny must be accounted for | `idempotency_key` (unique) |
| `settlement_log` | Immutable audit trail — proves settlement correctness | `idempotency_key` (unique) |
| `picks` | Player choices — basis for all settlement | `idempotency_key` (unique) |
| `leagues` | League configuration and stakes | N/A |
| `league_members` | Membership status, elimination state | N/A |
| `profiles` | User identity | N/A |

**Implementation option — Supabase cron + pg_dump to storage:**

```sql
-- This is a future enhancement. For launch, Supabase PITR is sufficient.
-- If secondary backups are needed, use a scheduled GitHub Action with
-- pg_dump against the prod connection string, uploading to cloud storage.
```

**Decision: For launch, Layer 1 (Supabase PITR) is sufficient.** Layer 2 can be added post-launch if required by compliance review (PYR-26).

---

## Existing Data Integrity Safeguards

These are already built into the schema and enforce correctness even during recovery:

### Settlement log — append-only audit trail
- RLS: `SELECT` only for league members. No `INSERT`, `UPDATE`, or `DELETE` policies for regular users.
- Only service-role (Edge Functions) can write to `settlement_log`.
- `idempotency_key` (unique constraint) prevents duplicate settlement entries.
- Attempting to re-settle the same pick produces a `23505` unique violation — caught as a no-op.

### Wallet transactions — idempotent and auditable
- Every transaction has a unique `idempotency_key` — replaying the same operation is safe.
- Wallet balances are **computed views** (`user_wallet_balances`), not stored values. Balance = `SUM(amount)` over all transactions. This means:
  - No balance drift — the balance is always correct as long as transaction rows are intact.
  - Recovery only needs to restore `wallet_transactions` rows; balances recompute automatically.
- Atomic operations (withdrawal, join-paid-league) use `SERIALIZABLE` isolation or advisory locks.

### Picks — idempotent submission
- `idempotency_key` (unique) on the picks table.
- Unique constraint on `(league_id, user_id, gameweek_id)` prevents duplicate picks per gameweek.
- `is_locked` flag prevents modification after deadline.

---

## Recovery Procedures

### Scenario 1: Accidental data deletion or corruption

**Symptoms:** Missing rows, wrong values, user reports data disappeared.

**Steps:**

1. **Assess scope** — which tables are affected? How many rows? What time did it happen?
   ```sql
   -- Check recent activity on affected table
   SELECT * FROM wallet_transactions
   ORDER BY created_at DESC LIMIT 20;
   ```

2. **Use PITR to restore** — Supabase Dashboard → Settings → Database → Backups → Restore to a point in time
   - Choose a timestamp **just before** the incident
   - This creates a **new project** with the restored data (it does NOT overwrite the current project)

3. **Extract missing data** from the restored project
   ```bash
   # Connect to restored project and export the affected table
   pg_dump -h <restored-host> -U postgres -t wallet_transactions --data-only > recovery.sql

   # Compare and selectively import into prod
   ```

4. **Apply missing rows** to production — carefully insert only the missing/corrupted rows.

5. **Verify** — check wallet balances recompute correctly, settlement log is consistent.

### Scenario 2: Full database failure

**Symptoms:** All queries fail, Supabase dashboard shows database unreachable.

**Steps:**

1. **Check Supabase status** — https://status.supabase.com/
2. **If Supabase-side outage** — wait for their resolution. No action needed.
3. **If project-specific failure:**
   a. Try restarting the database: Dashboard → Settings → General → Restart server
   b. If restart fails, initiate PITR restore to the latest available point
   c. After restore completes, update `SUPABASE_PROJECT_REF_PROD` and `SUPABASE_DB_PASSWORD_PROD` in GitHub Secrets if the project ref changes
   d. Re-deploy Edge Functions to the new project
   e. Update iOS app's Supabase URL if the project ref changed (requires TestFlight deploy)

4. **Verify recovery** — run the smoke test from [production-migration-strategy.md](./production-migration-strategy.md) Phase 5.

### Scenario 3: Settlement produces incorrect results

**Symptoms:** Users report wrong elimination/survival status, wallet balances don't match expectations.

**Steps:**

1. **Do NOT delete or modify existing settlement_log entries** — they are the audit trail.
2. **Identify the bad settlement:**
   ```sql
   SELECT * FROM settlement_log
   WHERE gameweek_id = <affected_gw>
   ORDER BY created_at DESC;
   ```

3. **Check the source data:**
   ```sql
   -- Were the fixture results correct when settlement ran?
   SELECT id, home_team_name, away_team_name, score_home, score_away, status
   FROM fixtures WHERE gameweek_id = <affected_gw>;
   ```

4. **If fixture data was wrong:** Re-sync fixtures (`sync-fixtures`), then re-run settlement. The idempotency key prevents duplicate credits — only new corrections will be applied.

5. **If settlement logic was wrong:** Fix the Edge Function code, deploy, and re-run settlement for the affected gameweek. Write a corrective wallet transaction if needed.

6. **Communicate** — notify affected users about the correction.

### Scenario 4: Edge Function deployment breaks production

**Symptoms:** App returns errors, health check shows unhealthy.

**Steps:**

1. **Roll back Edge Functions:**
   ```bash
   # Find last good deployment tag
   git tag --list 'prod-functions-*' --sort=-creatordate | head -5

   # Check out that tag and re-deploy
   git checkout <last-good-tag>
   # Trigger deploy-functions-prod workflow from GitHub Actions
   ```

2. **Database is unaffected** — Edge Function rollback doesn't touch the database.

3. **Verify** — run health check and smoke test.

---

## Critical Table Recovery Priority

If performing a selective restore, recover tables in this order:

| Priority | Table | Why |
|----------|-------|-----|
| 1 | `wallet_transactions` | Real money — balances derive from this |
| 2 | `settlement_log` | Audit trail — proves what happened |
| 3 | `picks` | Player choices — basis for settlement |
| 4 | `league_members` | Membership and elimination status |
| 5 | `leagues` | League configuration |
| 6 | `profiles` | User identity (auto-recreated on next login if lost) |
| 7 | `fixtures` / `gameweeks` | Reference data — can be re-synced from API-Football |
| 8 | `device_tokens` | Push notification tokens — users re-register automatically |
| 9 | `notification_preferences` | User preferences — low impact if lost |

---

## Testing the Recovery Plan

Before launch, verify the recovery process works:

- [ ] **PITR test:** Trigger a PITR restore on the dev project to confirm it completes successfully and data is intact
- [ ] **Idempotency test:** Run `settle-picks` twice for the same gameweek on dev — verify no duplicate entries or balance changes
- [ ] **Wallet consistency test:** After restore, verify `user_wallet_balances` view matches expected balances
- [ ] **RLS after restore:** Verify RLS policies are intact after PITR restore (they should be, but verify)

---

## Monitoring & Alerting

| Signal | Detection | Response |
|--------|-----------|----------|
| Health endpoint returns `unhealthy` | Uptime monitor (see [health-monitoring.md](./health-monitoring.md)) | Check database connectivity first, then follow Scenario 2 |
| Settlement older than 6 hours | Health endpoint `settlement` check warns | Manually trigger `settle-picks` or investigate API-Football data |
| Wallet balance discrepancy | User report or audit query | Follow Scenario 3 |
| API-Football quota > 80% | Health endpoint `api_football` check warns | Reduce sync frequency or upgrade API plan |

---

## Audit Queries

Run these periodically (weekly) to verify data integrity:

```sql
-- 1. Wallet balance consistency: no negative balances
SELECT user_id, balance
FROM user_wallet_balances
WHERE balance < 0;
-- Expected: 0 rows

-- 2. Settlement completeness: no FT fixtures with unsettled picks
SELECT p.id, p.league_id, p.gameweek_id, f.status
FROM picks p
JOIN fixtures f ON p.fixture_id = f.id
WHERE f.status = 'FT' AND p.result = 'pending';
-- Expected: 0 rows (or recently completed matches within settlement window)

-- 3. Idempotency key uniqueness: no duplicates
SELECT idempotency_key, count(*)
FROM settlement_log
GROUP BY idempotency_key
HAVING count(*) > 1;
-- Expected: 0 rows

-- 4. Orphaned picks: picks for non-existent fixtures
SELECT p.id FROM picks p
LEFT JOIN fixtures f ON p.fixture_id = f.id
WHERE f.id IS NULL;
-- Expected: 0 rows

-- 5. Eliminated members still active: data consistency
SELECT lm.id, lm.league_id, lm.user_id
FROM league_members lm
WHERE lm.status = 'eliminated'
AND EXISTS (
  SELECT 1 FROM picks p
  WHERE p.league_id = lm.league_id
  AND p.user_id = lm.user_id
  AND p.result = 'pending'
);
-- Expected: 0 rows (eliminated members shouldn't have pending picks)
```

---

## Contacts & Access

| Role | Who | Access |
|------|-----|--------|
| Supabase Dashboard (prod) | Jake Cox | Full admin |
| GitHub Actions (deploy) | Jake Cox | Repo admin |
| API-Football account | Jake Cox | Dashboard access |
| Supabase support | support@supabase.io | For platform-level incidents |
