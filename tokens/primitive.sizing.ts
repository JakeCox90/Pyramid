/**
 * Primitive Sizing Tokens
 * Source: Figma "Core - Theme" (Q3Cp3s8ZqChwPKEoYGmj1o)
 *   → 🛂 Border page (widths + radii)
 *   → 🌗 Effects page (shadows + blur)
 *   → 🅰️ Typography page (type scale)
 *
 * Raw sizing values only — no semantic meaning at this layer.
 * All values extracted directly from Figma via REST API.
 */

export const sizing = {
  // ─── Border Width ─────────────────────────────────────────────────
  // Token names from Figma: BorderWidth0..30
  borderWidth: {
    w0: 0,   // BorderWidth0 — no border
    w10: 1,  // BorderWidth10 — 1dp
    w20: 2,  // BorderWidth20 — 2dp
    w30: 4,  // BorderWidth30 — 4dp
  },

  // ─── Border Radius ────────────────────────────────────────────────
  // Token names from Figma: Radius0..60, Default, Pill, Full
  borderRadius: {
    r0: 0,     // Radius0 — sharp corners
    r05: 2,    // Radius05 — 2dp
    r10: 4,    // Radius10 — 4dp
    r20: 8,    // Radius20 — 8dp
    r30: 12,   // Radius30 — 12dp (Default)
    r40: 16,   // Radius40 — 16dp
    r45: 20,   // Radius45 — 20dp
    r50: 24,   // Radius50 — 24dp
    pill: 80,  // Pill — capsule shape
    full: 160, // Full — oval / circle
  },

  // ─── Shadow ───────────────────────────────────────────────────────
  // From Figma Effects page: Shadow section
  shadow: {
    low: {
      x: 0,
      y: 2,
      blur: 4,
      spread: 0,
      color: "rgba(32, 39, 59, 0.10)",
    },
    medium: {
      x: 0,
      y: 3,
      blur: 8,
      spread: 0,
      color: "rgba(32, 39, 59, 0.10)",
    },
    high: [
      {
        x: 0,
        y: 4,
        blur: 12,
        spread: 0,
        color: "rgba(32, 39, 59, 0.10)",
      },
      {
        x: 0,
        y: 4,
        blur: 4,
        spread: 0,
        color: "rgba(32, 39, 59, 0.10)",
      },
    ],
  },

  // ─── Typography Scale ─────────────────────────────────────────────
  // From Figma Typography page: table rows
  // Font families: Oswald (display), Montserrat (headings/body)
  typography: {
    fontFamily: {
      display: "Oswald",
      body: "Montserrat",
    },
    display: {
      d01: { fontSize: 28, lineHeight: 32, fontWeight: 700, transform: "uppercase", letterSpacing: 0 },
      d02: { fontSize: 18, lineHeight: 24, fontWeight: 700, transform: "uppercase", letterSpacing: 0 },
      d03: { fontSize: 14, lineHeight: 16, fontWeight: 700, transform: "uppercase", letterSpacing: 0 },
    },
    heading: {
      h01: { fontSize: 68, lineHeight: 80, fontWeight: 700, transform: "none", letterSpacing: 0 },
      h02: { fontSize: 47, lineHeight: 58, fontWeight: 700, transform: "none", letterSpacing: 0 },
      h03: { fontSize: 47, lineHeight: 58, fontWeight: 700, transform: "none", letterSpacing: 0 },
      h04: { fontSize: 24, lineHeight: 32, fontWeight: 700, transform: "none", letterSpacing: 0 },
      h05: { fontSize: 20, lineHeight: 28, fontWeight: 700, transform: "none", letterSpacing: 0 },
      h06: { fontSize: 16, lineHeight: 22, fontWeight: 700, transform: "none", letterSpacing: 0 },
    },
    subhead: {
      s01: { fontSize: 18, lineHeight: 26, fontWeight: 600, transform: "none", letterSpacing: 0 },
      s02: { fontSize: 14, lineHeight: 20, fontWeight: 600, transform: "none", letterSpacing: 0 },
    },
    label: {
      l01: { fontSize: 14, lineHeight: 20, fontWeight: 700, transform: "uppercase", letterSpacing: 0 },
      l02: { fontSize: 14, lineHeight: 20, fontWeight: 700, transform: "uppercase", letterSpacing: 0 },
      l03: { fontSize: 14, lineHeight: 20, fontWeight: 700, transform: "uppercase", letterSpacing: 0 },
    },
    body: {
      b01: { fontSize: 18, lineHeight: 26, fontWeight: 400, transform: "none", letterSpacing: 0 },
      b02: { fontSize: 16, lineHeight: 24, fontWeight: 400, transform: "none", letterSpacing: 0 },
    },
    meta: {
      caption: { fontSize: 14, lineHeight: 18, fontWeight: 600, transform: "none", letterSpacing: 0 },
      annotation: { fontSize: 12, lineHeight: 14, fontWeight: 600, transform: "none", letterSpacing: 0 },
    },
    form: {
      body: { fontSize: 14, lineHeight: 16, fontWeight: 400, transform: "none", letterSpacing: 0 },
      helper: { fontSize: 14, lineHeight: 18, fontWeight: 400, transform: "none", letterSpacing: 0 },
    },
  },
} as const;
