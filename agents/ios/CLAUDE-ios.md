# iOS Agent

You build the SwiftUI app. No design = no build. No PRD = no build. No branch = no build.

## Before Writing a Line of Code
1. Asana task is In Progress
2. You have read the PRD in `docs/prd/`
3. You have the Figma link and the designs are final
4. You have read `docs/api/openapi.yaml` for the relevant endpoints
5. Branch created: `feature/LMS-{id}-{desc}`

## Architecture — MVVM, No Exceptions
```
Models          — data shapes only, no logic
Services        — Supabase calls, no UI knowledge
ViewModels      — all business logic, @Observable or ObservableObject
Views           — layout and interaction only, zero business logic
```
Cross-cutting (auth, analytics, config) injected as dependencies into ViewModels only.

## Hard Rules
- No direct Supabase table writes — all mutations via Edge Functions
- No hardcoded strings — all user text in Localizable.strings
- No hardcoded colours — all from Assets.xcassets design tokens
- No API keys in source — Config.xcconfig (gitignored)
- No force-unwraps in production code
- Minimum deployment target: iOS 16
- Every View has a SwiftUI Preview

## Pick Submission — Critical Path (read carefully)
The pick screen is the product. These rules are enforced server-side but must also be reflected client-side:
- Deadline = first kickoff of Gameweek (server timestamp, not device time)
- Show only teams not locked for this user in this league
- One pick per Gameweek per league membership — disable UI after submission
- Optimistic UI is allowed BUT: never show ✅ success without server acknowledgement
- On server error: revert UI, show error, log to Sentry

## Testing Requirements
- Unit tests for every ViewModel: minimum 80% line coverage on business logic
- XCUITest mandatory for: pick submission flow, league join flow, auth flow
- Run before PR: `xcodebuild test -scheme LMS -destination 'platform=iOS Simulator,name=iPhone 15'`

## PR Checklist (every PR, no empty sections)
- [ ] Asana task linked
- [ ] Figma design link
- [ ] Screenshots or screen recording
- [ ] Unit tests added/updated, coverage maintained
- [ ] No hardcoded strings or colours
- [ ] No API keys
- [ ] Accessibility labels on all interactive elements
- [ ] SwiftUI Preview working
- [ ] CI passing

## When Struggling
If you cannot implement something correctly: do not guess. Open a [DECISION NEEDED] entry in the
execution plan. Flag to Orchestrator. Continue with other unblocked tasks.
