// Shared structured logger for Edge Functions
// Outputs JSON lines to stdout/stderr for indexing by Supabase log drain.
//
// Usage:
//   import { createLogger } from "../_shared/logger.ts";
//   const log = createLogger("settle-picks", req);
//   log.info("Settlement started", { fixtureId: 123 });
//   log.error("DB write failed", error, { leagueId: "abc" });
//   return log.complete("ok", response);

export interface Logger {
  readonly requestId: string;
  info(message: string, data?: Record<string, unknown>): void;
  warn(message: string, data?: Record<string, unknown>): void;
  error(message: string, err?: unknown, data?: Record<string, unknown>): void;
  /** Log completion with duration and return void. Use at end of handler. */
  complete(outcome: string, data?: Record<string, unknown>): void;
}

/**
 * Create a structured logger scoped to a single request.
 * Generates a request ID from the request headers (x-request-id) or crypto.randomUUID().
 */
export function createLogger(functionName: string, req?: Request): Logger {
  const requestId =
    req?.headers.get("x-request-id") ?? crypto.randomUUID();
  const startTime = performance.now();

  function emit(
    level: "info" | "warn" | "error",
    message: string,
    data?: Record<string, unknown>,
  ): void {
    const entry = {
      timestamp: new Date().toISOString(),
      level,
      function: functionName,
      requestId,
      message,
      duration_ms: Math.round(performance.now() - startTime),
      ...data,
    };
    const line = JSON.stringify(entry);
    if (level === "error") {
      console.error(line);
    } else if (level === "warn") {
      console.warn(line);
    } else {
      console.log(line);
    }
  }

  return {
    requestId,
    info(message: string, data?: Record<string, unknown>) {
      emit("info", message, data);
    },
    warn(message: string, data?: Record<string, unknown>) {
      emit("warn", message, data);
    },
    error(message: string, err?: unknown, data?: Record<string, unknown>) {
      const errorData: Record<string, unknown> = { ...data };
      if (err instanceof Error) {
        errorData.error = err.message;
        errorData.stack = err.stack;
      } else if (err != null) {
        errorData.error = String(err);
      }
      emit("error", message, errorData);
    },
    complete(outcome: string, data?: Record<string, unknown>) {
      emit("info", `${functionName} complete`, { outcome, ...data });
    },
  };
}
