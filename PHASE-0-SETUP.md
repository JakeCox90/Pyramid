# Phase 0 — Foundation Setup

## Phase 0 Linear Tasks

LMS-001: Set up Supabase project (dev + staging + prod)
LMS-002: Configure GitHub Actions CI (build + test)
LMS-003: Create Figma design system (colours, typography, spacing)
LMS-004: Write ADR-001: Database and backend platform choice
LMS-005: Write ADR-002: iOS tech stack choice
LMS-006: Write ADR-003: PL data provider choice
LMS-007: Create Notion workspace structure
LMS-008: Configure API-Football account and test fixture data
LMS-009: Write game rules specification (PM Agent)
LMS-010: [GATE 0] Human review: Decision log sign-off

## Notion Workspace Structure

Create a Notion page called "Last Man Standing" with sub-pages:
- Strategy & Vision
- Decision Log (Decision | Options | Recommended | Status | Approved By | Date)
- Architecture (ADRs)
- PRDs (one per feature)
- Status Updates (daily Orchestrator logs)
- Issues & Risks

## Gate 0 Checklist
- [ ] Tech stack (SwiftUI + Supabase) approved
- [ ] Data provider (API-Football) approved
- [ ] All decision log items reviewed
- [ ] Linear project set up
- [ ] Notion workspace set up
- [ ] GitHub branch protection active
- [ ] Supabase project provisioned

To approve Gate 0, respond to the Orchestrator's Notion page with:
APPROVED or APPROVED WITH CHANGES: [specify]
