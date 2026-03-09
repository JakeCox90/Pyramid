# Pyramid — Design System Specification

**Status:** Active — Phase 2 complete. Dark theme implemented. Light theme deferred.
**Original task:** PYR-7 / LMS-003 (Phase 0). Updated by PYR-60 (Phase 2).
**Date:** 2026-03-09
**For:** Figma Design System file + iOS implementation

> This document is the source of truth for all design tokens.
> Every value here must exist as a named style or variable in Figma.
> iOS engineers consume these tokens — names must match exactly.

---

## Figma File Structure

### Core Theme file (tokens — source of truth)

- **URL:** https://www.figma.com/design/D0hIZP7fHnn37d8EfXGJoM/Core---Theme
- **File key:** `D0hIZP7fHnn37d8EfXGJoM`
- **API:** Tokens are maintained via the Figma Variables API: `GET /v1/files/D0hIZP7fHnn37d8EfXGJoM/variables/local`
- **531 variables** across collections: Primitives (palette, sizing, opacity), Colour (semantic), Borders, Space, Fonts, Icon Size, Platform, Sub-Theming, Sub-Features, Sub-Components

> **Warning:** The Design System file (`5JZASzg6YxpCSatQyuZreo`) is empty and must NOT be used for token extraction. Only the Core Theme file above contains tokens.

### Exported token files

Tokens extracted from the Figma Variables API are stored at the repo root:

- `tokens/primitive/primitive.palette.json` — colour palette primitives
- `tokens/primitive/primitive.sizing.json` — sizing primitives
- `tokens/primitive/primitive.icons.json` — icon size primitives
- `tokens/primitive/primitive.logo.json` — logo primitives
- `tokens/semantic/semantic.color.json` — semantic colour mappings
- `tokens/semantic/semantic.border.json` — border tokens
- `tokens/semantic/semantic.spacing.json` — spacing tokens
- `tokens/semantic/semantic.elevation.json` — elevation/shadow tokens
- `tokens/semantic/semantic.typography.json` — typography tokens

### Figma pages

1. `Foundations` — colours, typography, spacing, shadows, radius
2. `Components` — buttons, inputs, cards, tags, avatars, nav
3. `Layout` — grid, safe areas, screen templates
4. `Accessibility` — contrast checks, touch targets
5. `Changelog` — version history

> **Note:** PYR-35 (Phase 2 design screens) was intentionally skipped for MVP. Phase 2 UI was built directly in SwiftUI using the token values below.

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

### Dark Theme (current default)

Dark mode is the current default for the app. Light mode is deferred to a future phase. All Phase 2 screens use this palette.

| Token Name | Value | Usage |
|---|---|---|
| `dark/background-primary` | `#0A0A0A` | Main screen background |
| `dark/background-secondary` | `#1C1C1E` | Grouped sections, cards |
| `dark/background-elevated` | `#2C2C2E` | Modals, sheets |
| `dark/text-primary` | `#FFFFFF` | Primary text |
| `dark/text-secondary` | `#EBEBF5` 60% opacity | Secondary text |
| `dark/text-tertiary` | `#EBEBF5` 30% opacity | Tertiary text, captions |
| `dark/brand` | `#1A56DB` | Primary actions (unchanged from light) |
| `dark/success` | `#30D158` | Win / survived (dark-mode adjusted) |
| `dark/error` | `#FF453A` | Loss / eliminated (dark-mode adjusted) |
| `dark/warning` | `#FFD60A` | Upcoming deadline, caution |
| `dark/separator` | `#38383A` | Dividers, borders |

> **Implementation:** Apply `.preferredColorScheme(.dark)` on root views until app-wide theme switching is implemented.

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

The Figma Variables API serves 531 variables across multiple collections (see "Figma File Structure" above for details). The variable collection supports both Light and Dark modes.

All colour tokens are mapped as Figma Variables. Spacing tokens are mapped as Number variables. Exported JSON files live in `tokens/primitive/` and `tokens/semantic/` at the repo root.

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
