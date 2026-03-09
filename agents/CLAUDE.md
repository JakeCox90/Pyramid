# Last Man Standing — Agent Entry Point
> This file is a MAP. It points you to docs/. It does not repeat what docs/ contains.
> Keep this file under 120 lines. If adding content here, ask: does this belong in docs/ instead?

## What This Project Is
Premier League Last Man Standing iOS app. Free + paid staking leagues. SwiftUI. Supabase backend.
Human owner is the team manager and sole gate approver. Agents execute. Humans steer.

## Read Before Anything Else
| If you are...                      | Read first |
|------------------------------------|---|
| Starting any session               | `docs/plans/active/` — find your current execution plan |
| Making an architecture decision    | `docs/adr/` — check if it's already decided |
| Building any feature               | `docs/prd/` — find the PRD and acceptance criteria |
| Touching game logic                | `docs/game-rules/` — the authoritative rules spec |
| Touching payments/compliance       | `docs/compliance/` — stop and read everything there |
| Unsure about a pattern             | `docs/golden-principles.md` |
| Unsure about process               | `docs/agent-operating-principles.md` — this is the authority |

## The 5 Rules That Override Everything
1. **If it's not in docs/, it doesn't exist.** Context in chat or someone's head is invisible to you.
2. **Failing CI = PR does not merge.** No exceptions.
3. **GATE decisions = stop and escalate.** Never guess on decisions marked GATE.
4. **Settlement code = human review always.** No exceptions.
5. **Struggling = fix the environment first.** Missing tool/doc/guardrail beats re-prompting.

## Task Flow (every task, every time)
```
Find/create Linear task → In Progress
→ Read PRD + active execution plan
→ Branch: feature/LMS-{id}-{desc}
→ Build → CI passes → PR with template
→ Move Linear to In Review
→ Agent-to-agent review (QA + specialist)
→ Human review only if required (see docs/agent-operating-principles.md §5.3)
→ Merge → Linear Done
```

## Repo Structure
```
/
├── ios/                           # SwiftUI app (MVVM strict)
├── supabase/
│   ├── migrations/                # Versioned .sql, always reversible
│   └── functions/                 # Edge Functions — no direct DB writes from client
├── docs/
│   ├── adr/                       # Architecture decisions
│   ├── prd/                       # Feature requirements + acceptance criteria
│   ├── game-rules/                # Pick, settlement, consolation, staking rules
│   ├── plans/active/              # Execution plans in flight
│   ├── plans/completed/           # Completed plans — never delete
│   ├── quality/                   # Coverage, quality scores
│   ├── compliance/                # UKGC, KYC, GDPR
│   ├── design-system/             # Tokens, components, accessibility
│   ├── golden-principles.md       # Encoded human taste — must follow
│   └── agent-operating-principles.md
├── agents/                        # Per-agent CLAUDE.md files
├── .github/
│   ├── workflows/                 # CI: build, test, lint, secret-scan
│   └── pull_request_template.md
└── CLAUDE.md                      # This file — map only
```

## Branch Naming
- `main` — production, protected, 1 human approval
- `feature/LMS-{id}-{desc}` | `fix/LMS-{id}-{desc}` | `chore/LMS-{id}-{desc}`

## Current Phase
See `docs/plans/active/phase-current.md`
