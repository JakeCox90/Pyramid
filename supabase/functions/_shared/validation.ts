// Shared input validation helpers for Edge Functions.
// All user-facing functions should validate inputs at the boundary
// before passing data to the service layer.

const UUID_V4_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/** Validates that a string is a UUID v4 format. */
export function isUUID(s: unknown): s is string {
  return typeof s === "string" && UUID_V4_RE.test(s);
}

/** Validates that a value is a positive integer (> 0). */
export function isPositiveInteger(n: unknown): n is number {
  return typeof n === "number" && Number.isInteger(n) && n > 0;
}

/** Validates that a value is an integer within [min, max] (inclusive). */
export function isIntInRange(n: unknown, min: number, max: number): n is number {
  return typeof n === "number" && Number.isInteger(n) && n >= min && n <= max;
}

/**
 * Trims, truncates to maxLen, and strips control characters from a string.
 * Returns the sanitized string.
 */
export function sanitizeString(s: string, maxLen: number): string {
  // Strip C0/C1 control characters except common whitespace (space, tab, newline)
  const stripped = s.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, "");
  return stripped.trim().slice(0, maxLen);
}

/**
 * Validates a financial amount in pence.
 * Returns { valid: true } or { valid: false, error: "reason" }.
 */
export function validateAmountPence(
  n: unknown,
  min: number,
  max: number,
): { valid: true } | { valid: false; error: string } {
  if (typeof n !== "number") {
    return { valid: false, error: "Amount must be a number" };
  }
  if (!Number.isInteger(n)) {
    return { valid: false, error: "Amount must be a whole number (pence)" };
  }
  if (n < min) {
    return { valid: false, error: `Amount must be at least ${min} pence` };
  }
  if (n > max) {
    return { valid: false, error: `Amount must be at most ${max} pence (${max / 100} pounds)` };
  }
  return { valid: true };
}

/** Validates that a string matches alphanumeric characters only. */
export function isAlphanumeric(s: string): boolean {
  return /^[A-Za-z0-9]+$/.test(s);
}

/** Validates an APNs device token (64 hex characters). */
export function isValidAPNsToken(s: string): boolean {
  return /^[a-f0-9]{64}$/i.test(s);
}

/** Validates a Stripe payment intent ID format. */
export function isValidStripePaymentIntentId(s: string): boolean {
  return /^pi_[A-Za-z0-9]+$/.test(s);
}
