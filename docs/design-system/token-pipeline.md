# Design Token Pipeline

## Overview

The design token pipeline generates Swift source files from Figma design tokens. Figma is the single source of truth for all color, spacing, and border radius tokens.

```
Figma Variables API ──→ figma-token-fetcher.js ──→ generate-tokens.js ──→ Swift files
                                                                           ├── ThemeColors.swift
                                                                           ├── ThemeSpacing.swift
                                                                           └── ThemeTypography.swift
```

## Files

| File | Purpose |
|------|---------|
| `scripts/figma-token-fetcher.js` | Fetches variables from Figma API, resolves aliases, converts colors |
| `scripts/generate-tokens.js` | Transforms token data into generated Swift source files |
| `tokens/semantic/*.json` | Local JSON cache (offline fallback only — not source of truth) |
| `tokens/primitive/*.json` | Local JSON cache of primitive palette/sizing values |

## How It Works

### 1. Figma Fetch (`figma-token-fetcher.js`)

Calls `GET /v1/files/{file_key}/variables/local` on the Figma Variables API and processes the response:

- **Alias resolution**: Figma variables can reference other variables via `VARIABLE_ALIAS`. The fetcher recursively resolves these chains. Remote/external aliases (referencing other Figma files) are skipped gracefully.
- **Color conversion**: Figma stores colors as RGBA floats (0–1). The fetcher converts to hex (`#1A56DB`) or rgba (`rgba(32, 39, 59, 0.1)`) strings.
- **Multi-mode support**: Semantic colors have Light and Dark modes. Both are resolved independently.
- **Collection mapping**: Variables are grouped by Figma collection (Primitives, Colour, Space, Borders, Fonts).

### 2. Code Generation (`generate-tokens.js`)

Takes the structured token data and generates three Swift files:

- **ThemeColors.swift** — Semantic color tokens with light/dark adaptive values
- **ThemeSpacing.swift** — Spacing scale, border radius, shadows, gradients
- **ThemeTypography.swift** — Font styles and line heights (from JSON, not Figma Variables — text styles aren't expressible as Figma variables yet)

### 3. CI Freshness Check

The `token-check` job in `.github/workflows/ios-ci.yml` runs on every PR:

1. Fetches tokens from Figma using `FIGMA_TOKEN` secret
2. Regenerates all Swift files
3. Runs `git diff --exit-code` on the generated files
4. Fails if committed files don't match current Figma state

This catches both directions of drift: code changes that don't match Figma, and Figma changes that haven't been synced to code.

## Usage

### Regenerate tokens from Figma (primary workflow)

```bash
export FIGMA_TOKEN=figd_...
node scripts/generate-tokens.js
```

### Regenerate from cached JSON (offline/fallback)

```bash
node scripts/generate-tokens.js --from-cache
```

This reads from `tokens/` directory JSON files. Useful for offline development, but the JSON may be stale relative to Figma.

## Token Fallbacks

Three tokens are used in the codebase but currently missing from Figma. These are injected as hardcoded fallbacks in `generate-tokens.js`:

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `Content.Text.contrast` | `#FFFFFF` | `#20273B` | Avatar, StoryStandingCard, PlayersRemainingCard |
| `Content.Link.contrast` | `#FFFFFF` | `#FFFFFF` | TokenBrowserView |
| `Surface.Background.elevated` | `#FFFFFF` | `#3D3354` | Toast, MatchCard, DetailSheet, FixturePickRow |

These fallbacks only apply when the token is absent from Figma. Once added to Figma, the Figma value takes precedence automatically.

## Figma File Details

| Property | Value |
|----------|-------|
| File | Core — Theme |
| File key | `D0hIZP7fHnn37d8EfXGJoM` |
| API endpoint | `GET /v1/files/D0hIZP7fHnn37d8EfXGJoM/variables/local` |
| Auth | `X-FIGMA-TOKEN` header with Personal Access Token |

### Collections

| Collection | ID | Contains |
|------------|----|----------|
| Primitives | `VariableCollectionId:2006:223` | Palette colors, scale values, opacity, border widths |
| Colour | `VariableCollectionId:2006:221` | Semantic colors (light/dark modes) |
| Space | `VariableCollectionId:5030:11499` | Spacing scale |
| Borders | `VariableCollectionId:5030:11344` | Border radius values |
| Fonts | `VariableCollectionId:5510:123` | Font families, sizes, weights, line heights |

## CI Setup

The `FIGMA_TOKEN` GitHub Actions secret must be configured with a Figma Personal Access Token that has read access to the Core — Theme file. Without it, the `token-check` CI job will fail.

To create the secret:
1. Generate a PAT at figma.com → Account Settings → Personal Access Tokens
2. Add it as a repository secret named `FIGMA_TOKEN` in GitHub Settings → Secrets

## Security

- The Figma PAT is never logged, echoed, or written to generated files
- HTTPS with TLS certificate validation is enforced
- Figma variable names are validated against `/^[a-zA-Z][a-zA-Z0-9]*$/` before being used as Swift identifiers (prevents code injection via malicious variable names)
- API response size is capped at 50 MB
- Request timeout is 15 seconds

## Troubleshooting

### "FIGMA_TOKEN environment variable is required"
Set the env var: `export FIGMA_TOKEN=figd_...`
Or use offline mode: `node scripts/generate-tokens.js --from-cache`

### "Figma API returned status 403"
The token is invalid or expired. Generate a new PAT in Figma account settings.

### "Expected Figma collection not found"
A collection ID has changed (file was duplicated or collection recreated). Update `COLLECTION_IDS` in `figma-token-fetcher.js`.

### CI drift check fails
Someone updated tokens in Figma without regenerating the Swift files. Run:
```bash
export FIGMA_TOKEN=figd_...
node scripts/generate-tokens.js
git add ios/Pyramid/Sources/Shared/DesignSystem/Theme*.swift
git commit -m "chore: sync tokens with Figma"
```

### Circular alias warning
A Figma variable references itself (directly or through a chain). The affected token is silently skipped. Fix the alias chain in Figma.
