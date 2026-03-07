# Pyramid — Design System Specification

**Status:** In Progress — PYR-7 / LMS-003
**Date:** 2026-03-07
**For:** Figma Design System file

> This document is the source of truth for all design tokens.
> Every value here must exist as a named style or variable in Figma.
> iOS engineers consume these tokens — names must match exactly.

---

## Figma File Structure

Create one Figma file: **"Pyramid — Design System"**

Pages:
1. `🎨 Foundations` — colours, typography, spacing, shadows, radius
2. `🧩 Components` — buttons, inputs, cards, tags, avatars, nav
3. `📐 Layout` — grid, safe areas, screen templates
4. `♿ Accessibility` — contrast checks, touch targets
5. `📖 Changelog` — version history

---

## 1. Colour Palette

### Brand

| Token Name | Hex | Usage |
|---|---|---|
| `brand/primary` | `#1A56DB` | Primary actions, active states |
| `brand/primary-hover` | `#1646C0` | Button hover / pressed |
| `brand/primary-subtle` | `#EBF2FF` | Backgrounds behind primary elements |

### Neutrals

| Token Name | Hex | Usage |
|---|---|---|
| `neutral/900` | `#111827` | Primary text |
| `neutral/700` | `#374151` | Secondary text |
| `neutral/500` | `#6B7280` | Placeholder, captions |
| `neutral/300` | `#D1D5DB` | Borders, dividers |
| `neutral/100` | `#F3F4F6` | Subtle backgrounds |
| `neutral/000` | `#FFFFFF` | Surface / card backgrounds |

### Semantic

| Token Name | Hex | Usage |
|---|---|---|
| `semantic/success` | `#16A34A` | Win / survived |
| `semantic/success-subtle` | `#DCFCE7` | Win background badge |
| `semantic/error` | `#DC2626` | Loss / eliminated |
| `semantic/error-subtle` | `#FEE2E2` | Eliminated background badge |
| `semantic/warning` | `#D97706` | Upcoming deadline, caution |
| `semantic/warning-subtle` | `#FEF3C7` | Warning background |
| `semantic/info` | `#0891B2` | Informational |
| `semantic/info-subtle` | `#CFFAFE` | Info background |

### Background / Surface

| Token Name | Hex | Usage |
|---|---|---|
| `background/primary` | `#FFFFFF` | Main screen background |
| `background/secondary` | `#F9FAFB` | Tab background, grouped sections |
| `background/elevated` | `#FFFFFF` | Cards, sheets (with shadow) |

> **WCAG AA requirement:** All text colours must achieve minimum 4.5:1 contrast ratio against their background. Verify in the Accessibility page.

---

## 2. Typography

### Font Family

**Primary:** SF Pro (system font on iOS — do not use a custom font in Phase 0)

In Figma: use the SF Pro Text / SF Pro Display fonts (download from developer.apple.com/fonts if needed).

### Type Scale

| Token Name | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `text/display` | 34pt | Bold (700) | 41pt | Screen titles (large) |
| `text/title-1` | 28pt | Bold (700) | 34pt | Section headers |
| `text/title-2` | 22pt | Semibold (600) | 28pt | Card titles |
| `text/title-3` | 20pt | Semibold (600) | 25pt | Sub-section headers |
| `text/headline` | 17pt | Semibold (600) | 22pt | List item primary |
| `text/body` | 17pt | Regular (400) | 22pt | Body copy |
| `text/callout` | 16pt | Regular (400) | 21pt | Secondary body |
| `text/subheadline` | 15pt | Regular (400) | 20pt | Labels, metadata |
| `text/footnote` | 13pt | Regular (400) | 18pt | Captions |
| `text/caption-1` | 12pt | Regular (400) | 16pt | Small labels |
| `text/caption-2` | 11pt | Regular (400) | 13pt | Timestamps, fine print |

> Match Apple's Dynamic Type scale. All sizes in points (pt = px at 1x).

---

## 3. Spacing System

8pt base grid. All spacing values are multiples of 4pt.

| Token Name | Value | Usage |
|---|---|---|
| `space/1` | 4pt | Micro — icon gaps, tight groupings |
| `space/2` | 8pt | Small — within components |
| `space/3` | 12pt | — |
| `space/4` | 16pt | Default — standard padding |
| `space/5` | 20pt | — |
| `space/6` | 24pt | Section gaps |
| `space/8` | 32pt | Large gaps between sections |
| `space/10` | 40pt | — |
| `space/12` | 48pt | Extra large |
| `space/16` | 64pt | Page-level padding |

### Layout

| Token | Value | Notes |
|---|---|---|
| `layout/page-margin` | 16pt | Left/right screen margin |
| `layout/card-padding` | 16pt | Internal card padding |
| `layout/section-gap` | 24pt | Between page sections |
| `layout/safe-area-bottom` | 34pt | iPhone home indicator (use safeAreaInsets in SwiftUI) |

---

## 4. Border Radius

| Token Name | Value | Usage |
|---|---|---|
| `radius/sm` | 6pt | Tags, badges, small chips |
| `radius/md` | 10pt | Cards, inputs |
| `radius/lg` | 16pt | Sheets, modals |
| `radius/xl` | 24pt | Large feature cards |
| `radius/full` | 9999pt | Pills, avatar frames |

---

## 5. Shadows

| Token Name | Y | Blur | Spread | Colour | Usage |
|---|---|---|---|---|---|
| `shadow/sm` | 1 | 2 | 0 | `#000` 6% | Subtle card lift |
| `shadow/md` | 2 | 8 | 0 | `#000` 10% | Standard cards |
| `shadow/lg` | 4 | 16 | 0 | `#000` 12% | Modals, bottom sheets |

---

## 6. Component Inventory (Phase 0)

Build these as Figma components with variants. Each must have all relevant states.

### Button

Variants: `Primary` | `Secondary` | `Destructive` | `Ghost`
Sizes: `Large (50pt tall)` | `Medium (40pt tall)` | `Small (32pt tall)`
States: `Default` | `Hover` | `Pressed` | `Disabled` | `Loading`

- Large buttons: full width, `radius/md`, `text/headline`
- Always 44pt minimum touch target (accessibility)

### Text Input

States: `Empty` | `Focused` | `Filled` | `Error` | `Disabled`
- Border: `neutral/300` default, `brand/primary` focused, `semantic/error` error
- Label above field, error message below
- Height: 48pt, `radius/md`

### Card

Variants: `League Card` | `Pick Card` | `Result Card`
- Background: `background/elevated`, `shadow/md`, `radius/lg`, `space/4` padding
- League Card: league name, member count, gameweek status, your pick status

### Pick Status Badge

Variants: `Survived` | `Eliminated` | `Pending` | `Void`
- `Survived`: `semantic/success` text on `semantic/success-subtle` background
- `Eliminated`: `semantic/error` text on `semantic/error-subtle` background
- `Pending`: `neutral/700` text on `neutral/100` background
- `Void`: `semantic/warning` text on `semantic/warning-subtle` background
- `radius/full`, `space/2` vertical padding, `space/3` horizontal

### Team Chip

Used in pick flow — shows team crest + name.
States: `Unselected` | `Selected` | `Used` (already picked this season) | `Disabled`
- `radius/md`, `shadow/sm`, 60pt × 80pt

### Navigation / Tab Bar

4 tabs: Leagues | Picks | Results | Profile
- Uses SF Symbols (filled when active)
- Active colour: `brand/primary`
- Inactive: `neutral/500`

---

## 7. Icons

Use **SF Symbols** exclusively. No custom icon set in Phase 0.

Key symbols used:
- Leagues: `trophy` / `trophy.fill`
- Picks: `checkmark.circle` / `checkmark.circle.fill`
- Results: `chart.bar` / `chart.bar.fill`
- Profile: `person.circle` / `person.circle.fill`
- Eliminated: `xmark.circle.fill`
- Survived: `checkmark.circle.fill`
- Deadline: `clock` / `clock.fill`
- Lock: `lock.fill`

---

## 8. Figma Variables Setup

Create a **Variable Collection** called `Pyramid Tokens` with modes: `Light` (Phase 0 only — dark mode Phase 2).

Map all colour tokens as Figma Variables. Map spacing as Number variables. This enables design token export for iOS engineers.

---

## 9. Acceptance Criteria Checklist

- [ ] All colour tokens created as Figma Variables
- [ ] All type styles created as Figma Text Styles
- [ ] All spacing tokens documented
- [ ] Button component: all variants + states
- [ ] Text Input component: all states
- [ ] Card component: League Card, Pick Card, Result Card
- [ ] Pick Status Badge: all 4 variants
- [ ] Team Chip: all states
- [ ] WCAG AA contrast verified for all text/background combos (Accessibility page)
- [ ] Figma file shared with team
- [ ] Token names exported to `docs/design-system/tokens.md`
