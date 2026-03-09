# Scripts

## Token Pipeline: `generate-tokens.js`

Generates Swift design system files from JSON token definitions.

### Usage

```bash
node scripts/generate-tokens.js
```

### What it does

Reads token JSON files from `tokens/` and generates 3 Swift files in `ios/Pyramid/Sources/Shared/DesignSystem/`:

| Output | Source |
|--------|--------|
| `ThemeColors.swift` | `semantic/semantic.color.json` + `primitive/primitive.palette.json` |
| `ThemeSpacing.swift` | `semantic/semantic.spacing.json` + `semantic/semantic.border.json` + `primitive/primitive.sizing.json` |
| `ThemeTypography.swift` | `semantic/semantic.typography.json` |

### Files NOT generated (hand-written)

- `Theme.swift` — base enum + helper functions
- `Icons.swift` — SF Symbol constants (not token-driven)

### Adding a new token

1. Add the token to the appropriate JSON file in `tokens/semantic/`
2. If it references a new primitive, add that to `tokens/primitive/`
3. Update the script if a new enum/category is needed
4. Run `node scripts/generate-tokens.js`
5. Commit both the JSON and generated Swift files

### Adding a new typography style

Update the `typographyMap` array in `generate-tokens.js` with the new semantic name and its corresponding fontSize/fontWeight scale keys.

### CI validation

The `token-check` job in `.github/workflows/ios-ci.yml` runs the script and verifies the generated files match what's committed. If they differ, the job fails with instructions to regenerate.
