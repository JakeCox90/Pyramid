# Platform Token Outputs

Platform-specific token files are **generated artefacts** produced by running [Style Dictionary](https://amzn.github.io/style-dictionary/) transforms against the shared JSON token files in `tokens/primitive/` and `tokens/semantic/`.

**Never edit platform output files by hand.** All changes must go into the shared JSON token files, then regenerated.

## Token Pipeline

```
tokens/primitive/*.json  ─┐
                           ├──> Style Dictionary ──> platforms/ios/
tokens/semantic/*.json   ─┘                     ──> platforms/android/
                                                ──> platforms/web/ (future)
```

## Platform Transforms

| Platform | Format | Tool | Output |
|----------|--------|------|--------|
| iOS | Swift enums (`Color`, `CGFloat`, `Font`) | Style Dictionary Swift transform | `platforms/ios/` |
| Android | Kotlin / XML resource files | Style Dictionary Android transform | `platforms/android/` |
| Web (future) | CSS custom properties / JS | Style Dictionary CSS transform | `platforms/web/` |

## Generating Platform Outputs

```bash
# Install Style Dictionary
npm install -g style-dictionary

# Generate all platforms
style-dictionary build

# Generate a specific platform
style-dictionary build --platform ios
```

## Configuration

Style Dictionary is configured via `style-dictionary.config.json` (to be added when the build pipeline is set up). The config will:

1. Read all `tokens/primitive/*.json` and `tokens/semantic/*.json` as source
2. Resolve `{primitive.ref}` references to their raw values
3. Apply platform-specific transforms (e.g., hex to `Color`, px to `CGFloat`)
4. Output to the respective `platforms/<platform>/` directory

## Reference Format

Semantic tokens reference primitives using Style Dictionary's `{dot.notation}` syntax:

- `{palette.blue.50}` — references `primitive.palette.json` → `blue.50`
- `{sizing.30}` — references `primitive.sizing.json` → `scale.30`
- `{opacity.50}` — references `primitive.sizing.json` → `opacity.50`
