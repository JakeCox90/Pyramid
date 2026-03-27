// Shared Sentry integration for Edge Functions
// Wraps the Sentry Deno SDK so individual functions don't import Sentry directly.
//
// Usage:
//   import { initSentry, captureException, flushSentry } from "../_shared/sentry.ts";
//   initSentry();
//   try { ... } catch (err) { captureException(err, { function: "settle-picks" }); }
//   await flushSentry();

import * as Sentry from "https://deno.land/x/sentry@8.45.0/index.mjs";

let _initialised = false;

/** Initialise Sentry once per cold start. Safe to call multiple times. */
export function initSentry(): void {
  if (_initialised) return;

  const dsn = Deno.env.get("SENTRY_DSN_EDGE");
  if (!dsn) return;

  Sentry.init({
    dsn,
    environment: Deno.env.get("ENVIRONMENT") ?? "dev",
    tracesSampleRate: 0.2,
    beforeSend(event: Sentry.ErrorEvent) {
      // Strip query params from URLs in breadcrumbs to avoid leaking tokens
      if (event.breadcrumbs) {
        for (const crumb of event.breadcrumbs) {
          if (crumb.data?.url && typeof crumb.data.url === "string") {
            try {
              const url = new URL(crumb.data.url);
              url.search = "";
              crumb.data.url = url.toString();
            } catch {
              // not a valid URL, leave as-is
            }
          }
        }
      }
      return event;
    },
  });

  _initialised = true;
}

/** Capture an exception with optional tags. */
export function captureException(
  err: unknown,
  tags?: Record<string, string>,
): void {
  if (!_initialised) return;
  Sentry.withScope((scope: Sentry.Scope) => {
    if (tags) {
      for (const [key, value] of Object.entries(tags)) {
        scope.setTag(key, value);
      }
    }
    Sentry.captureException(err);
  });
}

/** Flush pending events before the function returns. */
export async function flushSentry(timeoutMs = 2000): Promise<void> {
  if (!_initialised) return;
  await Sentry.flush(timeoutMs);
}
