// Unit tests for shared validation helpers.
// Run with: deno test supabase/functions/_shared/validation.test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  isUUID,
  isPositiveInteger,
  isIntInRange,
  sanitizeString,
  validateAmountPence,
  isAlphanumeric,
  isValidAPNsToken,
  isValidStripePaymentIntentId,
} from "./validation.ts";

// ─── isUUID ──────────────────────────────────────────────────────────────────

Deno.test("isUUID: accepts valid UUID v4", () => {
  assertEquals(isUUID("550e8400-e29b-41d4-a716-446655440000"), true);
  assertEquals(isUUID("6ba7b810-9dad-41d1-80b4-00c04fd430c8"), true);
});

Deno.test("isUUID: rejects non-v4 UUIDs", () => {
  // v1 UUID (version digit = 1, not 4)
  assertEquals(isUUID("550e8400-e29b-11d4-a716-446655440000"), false);
});

Deno.test("isUUID: rejects invalid strings", () => {
  assertEquals(isUUID(""), false);
  assertEquals(isUUID("not-a-uuid"), false);
  assertEquals(isUUID("550e8400-e29b-41d4-a716"), false); // truncated
  assertEquals(isUUID("550e8400-e29b-41d4-a716-44665544000g"), false); // non-hex
});

Deno.test("isUUID: rejects non-string types", () => {
  assertEquals(isUUID(null), false);
  assertEquals(isUUID(undefined), false);
  assertEquals(isUUID(123), false);
  assertEquals(isUUID({}), false);
});

// ─── isPositiveInteger ───────────────────────────────────────────────────────

Deno.test("isPositiveInteger: accepts positive integers", () => {
  assertEquals(isPositiveInteger(1), true);
  assertEquals(isPositiveInteger(100), true);
  assertEquals(isPositiveInteger(999999), true);
});

Deno.test("isPositiveInteger: rejects zero, negatives, floats", () => {
  assertEquals(isPositiveInteger(0), false);
  assertEquals(isPositiveInteger(-1), false);
  assertEquals(isPositiveInteger(1.5), false);
  assertEquals(isPositiveInteger(-0.5), false);
});

Deno.test("isPositiveInteger: rejects non-numbers", () => {
  assertEquals(isPositiveInteger("1"), false);
  assertEquals(isPositiveInteger(null), false);
  assertEquals(isPositiveInteger(NaN), false);
  assertEquals(isPositiveInteger(Infinity), false);
});

// ─── isIntInRange ────────────────────────────────────────────────────────────

Deno.test("isIntInRange: accepts values within range (inclusive)", () => {
  assertEquals(isIntInRange(5, 1, 10), true);
  assertEquals(isIntInRange(1, 1, 10), true);  // lower bound
  assertEquals(isIntInRange(10, 1, 10), true); // upper bound
});

Deno.test("isIntInRange: rejects values outside range", () => {
  assertEquals(isIntInRange(0, 1, 10), false);
  assertEquals(isIntInRange(11, 1, 10), false);
  assertEquals(isIntInRange(-5, 1, 10), false);
});

Deno.test("isIntInRange: rejects floats and non-numbers", () => {
  assertEquals(isIntInRange(5.5, 1, 10), false);
  assertEquals(isIntInRange("5" as unknown as number, 1, 10), false);
  assertEquals(isIntInRange(NaN, 1, 10), false);
});

// ─── sanitizeString ──────────────────────────────────────────────────────────

Deno.test("sanitizeString: trims and truncates", () => {
  assertEquals(sanitizeString("  hello  ", 100), "hello");
  assertEquals(sanitizeString("abcdef", 3), "abc");
});

Deno.test("sanitizeString: strips control characters", () => {
  assertEquals(sanitizeString("hello\x00world", 100), "helloworld");
  assertEquals(sanitizeString("test\x07\x08\x0E\x1F", 100), "test");
  assertEquals(sanitizeString("\x7F\x80\x9F", 100), "");
});

Deno.test("sanitizeString: preserves normal whitespace", () => {
  assertEquals(sanitizeString("hello world", 100), "hello world");
  // tabs and newlines within content are preserved (trim only affects edges)
  assertEquals(sanitizeString("hello\tworld", 100), "hello\tworld");
});

Deno.test("sanitizeString: handles XSS payloads (passes through — HTML escaping is not its job)", () => {
  // sanitizeString strips control chars but does NOT HTML-escape.
  // XSS prevention is handled at the response layer (JSON + nosniff).
  const xss = '<script>alert("xss")</script>';
  assertEquals(sanitizeString(xss, 100), xss);
});

Deno.test("sanitizeString: handles SQL injection strings (passes through — parameterised queries prevent SQLi)", () => {
  const sqli = "'; DROP TABLE users; --";
  assertEquals(sanitizeString(sqli, 100), "'; DROP TABLE users; --");
});

// ─── validateAmountPence ─────────────────────────────────────────────────────

Deno.test("validateAmountPence: accepts valid amounts", () => {
  assertEquals(validateAmountPence(500, 1, 100000), { valid: true });
  assertEquals(validateAmountPence(1, 1, 100000), { valid: true });
  assertEquals(validateAmountPence(100000, 1, 100000), { valid: true });
});

Deno.test("validateAmountPence: rejects non-numbers", () => {
  const result = validateAmountPence("500", 1, 100000);
  assertEquals(result.valid, false);
  if (!result.valid) assertEquals(result.error, "Amount must be a number");
});

Deno.test("validateAmountPence: rejects floats", () => {
  const result = validateAmountPence(5.5, 1, 100000);
  assertEquals(result.valid, false);
  if (!result.valid) assertEquals(result.error, "Amount must be a whole number (pence)");
});

Deno.test("validateAmountPence: rejects below minimum", () => {
  const result = validateAmountPence(0, 1, 100000);
  assertEquals(result.valid, false);
  if (!result.valid) assertEquals(result.error, "Amount must be at least 1 pence");
});

Deno.test("validateAmountPence: rejects above maximum", () => {
  const result = validateAmountPence(100001, 1, 100000);
  assertEquals(result.valid, false);
  if (!result.valid) assertEquals(result.error, "Amount must be at most 100000 pence (1000 pounds)");
});

// ─── isAlphanumeric ──────────────────────────────────────────────────────────

Deno.test("isAlphanumeric: accepts alphanumeric strings", () => {
  assertEquals(isAlphanumeric("ABC123"), true);
  assertEquals(isAlphanumeric("abc"), true);
  assertEquals(isAlphanumeric("123"), true);
});

Deno.test("isAlphanumeric: rejects non-alphanumeric", () => {
  assertEquals(isAlphanumeric(""), false);
  assertEquals(isAlphanumeric("abc-123"), false);
  assertEquals(isAlphanumeric("hello world"), false);
  assertEquals(isAlphanumeric("abc_def"), false);
  assertEquals(isAlphanumeric("abc!"), false);
});

// ─── isValidAPNsToken ────────────────────────────────────────────────────────

Deno.test("isValidAPNsToken: accepts valid 64-char hex token", () => {
  assertEquals(isValidAPNsToken("a".repeat(64)), true);
  assertEquals(isValidAPNsToken("1234567890abcdef".repeat(4)), true);
});

Deno.test("isValidAPNsToken: rejects invalid tokens", () => {
  assertEquals(isValidAPNsToken(""), false);
  assertEquals(isValidAPNsToken("a".repeat(63)), false);  // too short
  assertEquals(isValidAPNsToken("a".repeat(65)), false);  // too long
  assertEquals(isValidAPNsToken("g".repeat(64)), false);  // non-hex
});

// ─── isValidStripePaymentIntentId ────────────────────────────────────────────

Deno.test("isValidStripePaymentIntentId: accepts valid IDs", () => {
  assertEquals(isValidStripePaymentIntentId("pi_3abc123"), true);
  assertEquals(isValidStripePaymentIntentId("pi_ABC"), true);
});

Deno.test("isValidStripePaymentIntentId: rejects invalid IDs", () => {
  assertEquals(isValidStripePaymentIntentId(""), false);
  assertEquals(isValidStripePaymentIntentId("pi_"), false);
  assertEquals(isValidStripePaymentIntentId("ch_3abc123"), false); // wrong prefix
  assertEquals(isValidStripePaymentIntentId("pi_abc-123"), false); // hyphen not allowed
});
