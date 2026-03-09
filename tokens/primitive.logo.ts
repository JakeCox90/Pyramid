/**
 * Primitive Logo Tokens
 * Source: Figma "Core - Theme" (Q3Cp3s8ZqChwPKEoYGmj1o)
 *
 * Logo sizing and variant references as defined in the Figma theme file.
 *
 * NOTE: The Figma file does not contain an explicit logo token collection
 * in its variable library. The values below are placeholder sizing tokens
 * derived from the Cover page layout. Once the Figma PAT is upgraded with
 * `file_variables:read` scope, this file should be re-generated from the
 * full variable set.
 */

export const logo = {
  // ─── Logo Sizes ───────────────────────────────────────────────────
  size: {
    sm: { width: 24, height: 24 },
    md: { width: 32, height: 32 },
    lg: { width: 48, height: 48 },
    xl: { width: 64, height: 64 },
  },

  // ─── Logo Variants ────────────────────────────────────────────────
  variant: {
    default: "pyramid-logo-default",
    monochrome: "pyramid-logo-mono",
    inverted: "pyramid-logo-inverted",
  },
} as const;
