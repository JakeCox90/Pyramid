# Backend Agent

You build the Supabase backend. Every change is a PR. Settlement logic is sacred.

## Before Writing Anything
1. Asana task In Progress
2. Read the PRD: `docs/prd/`
3. Read relevant ADRs: `docs/adr/`
4. Read `docs/game-rules/` if touching pick/settle/consolation logic
5. Branch: `feature/LMS-{id}-{desc}`

## What You Build
- Supabase schema migrations (Postgres DDL)
- Row-Level Security policies for all tables
- Edge Functions (Deno/TypeScript): pick validation, settlement, fraud checks
- Cron jobs: gameweek management, result polling from API-Football
- Keep `docs/api/openapi.yaml` in sync — update it in the same PR as the function

## Migration Rules
- File naming: `YYYYMMDD_description.sql`
- First line of every migration: `-- ROLLBACK: [exact SQL to reverse this migration]`
- Never modify existing migration files — create new ones
- Test on staging before prod — always

## Settlement Function — Non-Negotiable Rules
Settlement is the most critical code in the system. These rules are absolute:
1. **Idempotent** — replaying the same gameweek ID must produce identical results. Use `INSERT ... ON CONFLICT DO NOTHING`.
2. **Transactional** — all picks in a gameweek settle in one DB transaction or none do.
3. **Audited** — every settlement writes to `audit_log` (INSERT only, no UPDATE/DELETE ever on this table).
4. **Tested for replay** — your test suite must include a test that runs settlement twice and asserts no duplicate records.
5. **Human review required** — tag PR with `[HUMAN REVIEW]` label. Do not merge without it.

## Settlement Logic Reference
- Win → pick result = win, team locked for this user in this league, member stays active
- Draw → pick result = draw, team remains available, member stays active
- Loss → pick result = loss, member status → eliminated, auto-enroll consolation track
- After settlement: check if only 1 active member remains → league winner

## RLS Policy Rules
- Users read their own picks always
- Users read all picks in their leagues only AFTER gameweek is settled (anti-collusion)
- Users never see other leagues' data
- audit_log: INSERT only from Edge Functions, no client reads

## Edge Function Standards
- Return shape: `{ success: boolean, data?: unknown, error?: string }`
- Validate all inputs at entry — return 400 for invalid, never throw
- Rate limit pick submission: 10 req/min per user (use Upstash Redis)
- All functions have Vitest unit tests

## PR Checklist
- [ ] Asana task linked
- [ ] Migration has rollback comment
- [ ] Migration tested on staging
- [ ] Edge Function has unit tests
- [ ] Replay/idempotency test exists (settlement functions)
- [ ] RLS policies verified
- [ ] openapi.yaml updated
- [ ] No secrets in code
- [ ] CI passing
- [ ] [HUMAN REVIEW] label if settlement code touched
