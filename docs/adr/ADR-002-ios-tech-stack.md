# ADR-002: iOS Tech Stack Choice

**Status:** APPROVED — Gate 0 signed off 2026-03-07
**Date:** 2026-03-07
**Deciders:** Architect Agent, Orchestrator
**Approver:** Human owner (GATE 0)
**Linear:** PYR-9 / LMS-005

---

## Context

Pyramid is an iOS-only app (Phase 0–1). It requires:
- A clean, modern UI with strong animation support (pick flows, countdown timers, elimination reveals)
- State management that can handle real-time updates (pick deadlines, live results)
- Supabase iOS SDK integration for auth, database queries, and realtime subscriptions
- Rapid iteration — the team is agent-driven; the framework must be easy for agents to reason about consistently
- Testability — business logic must be unit-testable without a running UI
- Minimum deployment target: iOS 16

---

## Options Considered

### Option A: SwiftUI + MVVM (Recommended)

**What it is:** Apple's declarative UI framework, using MVVM (Model-View-ViewModel) as the architecture pattern.

**Strengths:**
- Declarative — UI is a pure function of state; far fewer bugs than imperative UIKit
- First-class Apple support — new APIs appear in SwiftUI first
- Strong animation primitives — ideal for pick flows and result reveals
- `@Observable` (iOS 17) and `ObservableObject` (iOS 16) — clean, testable state
- MVVM strict separation: ViewModels contain all business logic; Views are pure UI
- Works natively with Swift Concurrency (`async/await`, `Actor`)
- Supabase has a Swift SDK with async/await support
- Agents produce consistent, readable SwiftUI code
- Preview-driven development speeds up UI iteration

**Weaknesses:**
- Some complex UIKit components require `UIViewRepresentable` wrappers
- Navigation can be complex for deeply nested flows (use `NavigationStack`)
- Older SwiftUI bugs (iOS 14/15) not a concern since we target iOS 16+

**Architecture:** MVVM strict
- `View` — SwiftUI view, no business logic, no direct data access
- `ViewModel` — `@Observable` class, owns all state and business logic, calls Services
- `Service` — pure Swift, calls Supabase SDK, returns domain models
- `Model` — Codable structs, pure data

---

### Option B: UIKit

**What it is:** Apple's imperative UI framework, the foundation of all iOS apps pre-SwiftUI.

**Strengths:**
- Maximum control and maturity
- All third-party UI libraries support it
- Performance ceiling is higher for very complex custom UIs

**Weaknesses:**
- Imperative — significantly more boilerplate; harder for agents to produce consistently correct code
- View controllers become complex state machines quickly
- No declarative previews — slower UI iteration
- New Apple APIs often require additional UIKit bridging
- Not the direction Apple is investing in

---

### Option C: React Native

**What it is:** Cross-platform framework using JavaScript/TypeScript rendering native components.

**Strengths:**
- Cross-platform (iOS + Android in one codebase)
- Large ecosystem

**Weaknesses:**
- We are iOS-only — cross-platform is not a benefit at this stage
- Bridge overhead; native feel is harder to achieve
- Supabase JS SDK works but adds JS runtime complexity
- Agents produce less consistent React Native code for this project context
- App Store review is more complex for RN apps with staking

---

## Decision

**Recommended: SwiftUI + MVVM strict**

SwiftUI is the correct choice for a new iOS app targeting iOS 16+. Its declarative model maps well to agent-driven development (consistent, readable, testable). MVVM strict enforces clean separation: ViewModels are fully unit-testable without running the UI.

UIKit is a step backward for new development. React Native offers no cross-platform benefit for an iOS-only app.

---

## Architecture Rules (Non-Negotiable)

These rules apply to every line of iOS code written for Pyramid:

1. **Views contain no business logic.** No API calls, no data transformation, no conditional business rules in View files.
2. **ViewModels own all state.** Marked `@Observable` (iOS 17) or `ObservableObject` (iOS 16 compat). Injected into Views via environment or initialiser.
3. **Services are pure Swift.** No SwiftUI imports in Service files. Fully unit-testable.
4. **No direct Supabase calls from Views.** All Supabase interactions go through a Service layer.
5. **All async work uses Swift Concurrency.** No callbacks, no Combine (unless bridging unavoidable).
6. **No secrets in code.** API keys and Supabase URLs loaded from environment / Info.plist at build time.

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| SwiftUI quirks on iOS 16 | Medium | Low | Target iOS 16 minimum; test on iOS 16 device/simulator in CI |
| Complex navigation (multi-level pick flows) | Medium | Medium | Use `NavigationStack` with path-based routing from Phase 1 |
| Supabase Swift SDK immaturity | Low | Medium | Pin SDK version; write integration tests against staging |
| Agent inconsistency in large ViewModels | Low | Medium | MVVM rules enforced via code review checklist in agent CLAUDE.md |

---

## References

- [SwiftUI documentation](https://developer.apple.com/documentation/swiftui)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- ADR-001 (Supabase backend) — this ADR assumes Supabase as backend
- agents/ios/CLAUDE-ios.md — iOS agent rules
