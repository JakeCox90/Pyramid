# Golden Principles
> Encoded human taste. These are rules, not suggestions. CI will enforce what it can.
> When you spot a violation: fix the instance + add a lint rule + scan and fix all other instances.

## Code Quality
- Validate data at every boundary — never trust external input including API-Football results
- Shared utilities over hand-rolled helpers — one implementation, one test suite, one place to fix
- Errors are typed enums, never raw strings — structured throughout the entire stack
- Every async operation has a timeout — no unbounded waits anywhere
- No force-unwraps in production iOS code — handle optionals explicitly
- No `any` in TypeScript Edge Functions — type everything

## Observability
- Logs, metrics, and traces ship before the feature goes live, not after
- All logs are structured (JSON) — no free-text log lines in production code
- Every Edge Function emits a request-level trace
- Settlement functions log input, output, and duration for every invocation

## Testing
- Settlement functions: idempotency test is mandatory — replay and assert no duplicates
- Business logic lives in ViewModels (iOS) and Edge Functions (backend) — these are the test targets
- Acceptance criteria from PRDs are the source of truth for what to test
- 80% line coverage on business logic — not a target, a minimum

## Architecture
- One pattern, one place — if it exists in ten places, it belongs in a shared utility
- No pattern introduced without an ADR or a PRD backing it
- Layer boundaries are hard — no skipping, no importing across layers
- Every third-party integration has an owned wrapper — scattered raw SDK calls are banned

## Settlement is Sacred
- Never ship settlement changes without human review
- Double-check every edge case against `docs/game-rules/`
- If in doubt about a rules interpretation: create a [DECISION NEEDED] entry, do not guess
- Idempotency + auditability are not optional features — they are the foundation

## Design System is Sacred
- Every UI component lives in the design system — zero hardcoded components in feature code
- Every design system component is registered in the design system browser — if it's not browsable, it doesn't exist
- New features are composed from existing design system components — create or extend in the design system first, never build one-offs
- Every component is unique within its context — no similar components doing slightly different things; consolidate into one with variants
- Breaking these rules = GATE — stop, flag to the human, wait for their call

## Entropy Prevention
- Update the relevant doc in the same PR as the code change — never separate
- Stale docs are worse than no docs — they cause confident wrong behaviour
- When a pattern is fixed, scan the whole codebase — never fix one and leave nine
- Small debt paid daily beats large debt paid in a crisis
