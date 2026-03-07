# ADR-001: Database and Backend Platform Choice

**Status:** Proposed — Pending GATE 0 approval
**Date:** 2026-03-07
**Deciders:** Architect Agent, Orchestrator
**Approver:** Human owner (GATE 0)
**Linear:** PYR-8 / LMS-004

---

## Context

Pyramid requires a backend platform that can handle:
- User authentication and session management
- Real-time pick submission and deadline enforcement
- Settlement logic for eliminations (must be idempotent and auditable)
- Financial transaction records for staking leagues
- Row-level security to ensure users can only see their own data
- Edge Functions for server-side logic (no direct DB writes from iOS client)
- Multiple environments: dev, staging, prod

The platform must be developer-friendly for a small team with agent-assisted development, and must support the security and compliance requirements of a product involving real money.

---

## Options Considered

### Option A: Supabase (Recommended)

**What it is:** Open-source Firebase alternative built on PostgreSQL, with built-in Auth, Realtime, Storage, and Edge Functions (Deno).

**Strengths:**
- PostgreSQL — mature, reliable, full SQL support, strong RLS
- Built-in Auth with JWT — no separate auth service needed
- Row Level Security enforced at DB level — security by default
- Edge Functions (Deno/TypeScript) — all server-side mutations run here, never direct from client
- Realtime subscriptions — useful for live pick deadline countdowns
- Self-hostable — no vendor lock-in
- Excellent Supabase CLI for local dev and migrations
- Strong community and rapidly improving product
- Generous free tier; predictable pricing at scale

**Weaknesses:**
- Edge Functions are Deno-based (TypeScript) — less ecosystem than Node.js
- Relatively newer than Firebase; some features still maturing
- Realtime has scale limits on lower tiers

**Estimated cost:** ~£0–25/month at Phase 0–1 scale; scales predictably

---

### Option B: Firebase (Google)

**What it is:** Google's BaaS platform using Firestore (NoSQL) and Cloud Functions.

**Strengths:**
- Mature, battle-tested at scale
- Strong mobile SDK including iOS
- Cloud Functions well-supported

**Weaknesses:**
- Firestore is NoSQL — relational queries (joins, aggregates) are cumbersome
- Settlement logic involving financial records benefits strongly from relational guarantees (ACID transactions, foreign keys)
- No row-level security equivalent — security rules are more complex to reason about
- Vendor lock-in to Google Cloud
- Cost at scale can be unpredictable (read-heavy workloads)

---

### Option C: Custom Rails + PostgreSQL

**What it is:** A custom-built API using Ruby on Rails backed by PostgreSQL, self-hosted or on a cloud provider.

**Strengths:**
- Full control over every aspect of the stack
- PostgreSQL — same relational benefits as Supabase
- Mature Rails ecosystem for financial/transactional applications

**Weaknesses:**
- Significantly more engineering overhead — no built-in auth, realtime, storage
- Requires separate infrastructure (hosting, DB, CDN, auth service)
- Far higher cost in both engineering time and infrastructure
- Not appropriate for a lean agent-driven team in Phase 0

---

## Decision

**Recommended: Supabase**

Supabase provides the best combination of PostgreSQL's relational guarantees, built-in auth, row-level security, and Edge Functions. The Edge Functions pattern enforces our core architecture principle: no direct DB writes from the iOS client.

The settlement and staking logic requires ACID transactions and auditable records — PostgreSQL provides both. Firebase's NoSQL model would make this significantly harder to reason about and audit.

A custom Rails stack is disproportionate for a lean Phase 0 team.

---

## Architecture Implications

- All DB mutations from the iOS app must go via Supabase Edge Functions
- RLS policies are required on every table — no table is publicly readable/writable
- Three projects provisioned: `pyramid-dev`, `pyramid-staging`, `pyramid-prod`
- Migrations managed via Supabase CLI, versioned in `supabase/migrations/`
- All secrets stored as environment variables — never in source code
- Settlement Edge Functions must be idempotent (safe to replay)

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Supabase Edge Functions Deno ecosystem limitations | Low | Medium | Use standard Web APIs; avoid Node-specific libraries |
| Realtime at scale hitting tier limits | Low | Low | Monitor usage; upgrade tier before limits hit |
| Supabase product immaturity for financial use | Low | High | All financial logic in Edge Functions with extensive test coverage; idempotency keys on all settlement operations |
| Vendor lock-in | Low | Medium | PostgreSQL is standard SQL; migration to self-hosted Supabase or vanilla Postgres is feasible |

---

## References

- [Supabase docs](https://supabase.com/docs)
- [Row Level Security guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions guide](https://supabase.com/docs/guides/functions)
- ADR-002 (iOS tech stack) — references Supabase iOS SDK
- PHASE-0-SETUP.md — LMS-001 (Supabase provisioning task)
