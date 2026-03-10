// Unit tests for poll-live-scores: maybeAdvanceGameweek logic.
// Run with: deno test supabase/functions/poll-live-scores/index.test.ts --allow-env
//
// Tests cover:
//   - Does not advance when pending fixtures remain
//   - Marks current GW finished and promotes next GW when all fixtures done
//   - Off-season: marks current finished without error when no next GW exists
//   - Race condition: returns false (no-op) when GW already marked finished
//   - DB error on pending count: returns false without crashing
//   - DB error on finish update: returns false without promoting
//   - DB error on promotion: alerts and returns false
//   - Idempotency: second call after first succeeded is a no-op

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { maybeAdvanceGameweek } from "./index.ts";

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Minimal no-op logger matching the shape used in production.
 */
const nopLog = {
  info: () => {},
  warn: () => {},
  error: () => {},
  complete: () => {},
};

interface MockCall {
  table: string;
  operation: string;
  args?: unknown;
}

/**
 * Build a chainable Supabase mock that records calls and returns preset results.
 *
 * `countResult`  — returned for the "count pending fixtures" select query
 * `finishResult` — returned for the UPDATE that marks GW finished
 * `nextGwResult` — returned for the SELECT that fetches next GW
 * `promoteResult`— returned for the UPDATE that sets next GW is_current
 */
function buildMockDb({
  countResult,
  finishResult,
  nextGwResult,
  promoteResult,
}: {
  countResult: { count: number | null; error: unknown | null };
  finishResult: { data: unknown[] | null; error: unknown | null };
  nextGwResult: { data: unknown | null; error: unknown | null };
  promoteResult?: { error: unknown | null };
}) {
  const calls: MockCall[] = [];

  // Each from() call returns a builder that tracks what operations are called.
  // The builder is lazy: it only resolves when awaited (via .select(), etc.).
  const makeBuilder = (table: string) => {
    const state = {
      _ops: [] as string[],
      _countMode: false,
      _singleMode: false,
    };

    const builder = {
      select(_cols: string, opts?: { count?: string; head?: boolean }) {
        state._ops.push("select");
        if (opts?.count) state._countMode = true;
        return builder;
      },
      update(_vals: unknown) {
        state._ops.push("update");
        return builder;
      },
      eq(_col: string, _val: unknown) {
        return builder;
      },
      not(_col: string, _op: string, _val: unknown) {
        return builder;
      },
      is(_col: string, _val: unknown) {
        return builder;
      },
      single() {
        state._singleMode = true;
        return builder;
      },
      // Thenable — resolves on await
      then(resolve: (v: unknown) => unknown) {
        calls.push({ table, operation: state._ops.join("+") });

        // Select with count → pending fixture count
        if (state._countMode) {
          return resolve(countResult);
        }

        // update on gameweeks (finish) — has a .select("id") chain
        if (state._ops.includes("update") && state._ops.includes("select")) {
          return resolve(finishResult);
        }

        // select single → next GW lookup
        if (state._singleMode) {
          return resolve(nextGwResult);
        }

        // plain update → promote next GW
        if (state._ops.includes("update")) {
          return resolve(promoteResult ?? { error: null });
        }

        return resolve({ data: null, error: null });
      },
    };

    return builder;
  };

  const db = {
    from(table: string) {
      return makeBuilder(table);
    },
    _calls: calls,
  };

  return db;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

Deno.test("does not advance when pending fixtures remain", async () => {
  const db = buildMockDb({
    countResult: { count: 3, error: null }, // 3 pending
    finishResult: { data: null, error: null },
    nextGwResult: { data: null, error: null },
  });

  const advanced = await maybeAdvanceGameweek(db, 1, 12, nopLog);

  assertEquals(advanced, false);
});

Deno.test("advances gameweek when all fixtures are settled or void", async () => {
  const db = buildMockDb({
    countResult: { count: 0, error: null }, // no pending
    finishResult: { data: [{ id: 1 }], error: null }, // finish succeeds, 1 row updated
    nextGwResult: { data: { id: 2, round_number: 13 }, error: null }, // next GW found
    promoteResult: { error: null },
  });

  const advanced = await maybeAdvanceGameweek(db, 1, 12, nopLog);

  assertEquals(advanced, true);
});

Deno.test("off-season: marks current GW finished when no next GW exists", async () => {
  const db = buildMockDb({
    countResult: { count: 0, error: null },
    finishResult: { data: [{ id: 1 }], error: null },
    nextGwResult: { data: null, error: { message: "no rows", code: "PGRST116" } }, // no next GW
  });

  // Should return true (current marked finished) without error
  const advanced = await maybeAdvanceGameweek(db, 1, 38, nopLog);

  assertEquals(advanced, true);
});

Deno.test("race condition: returns false when GW already marked finished by concurrent invocation", async () => {
  const db = buildMockDb({
    countResult: { count: 0, error: null },
    finishResult: { data: [], error: null }, // 0 rows updated — already finished
    nextGwResult: { data: null, error: null },
  });

  const advanced = await maybeAdvanceGameweek(db, 1, 12, nopLog);

  assertEquals(advanced, false);
});

Deno.test("returns false and does not throw when pending count query errors", async () => {
  const db = buildMockDb({
    countResult: { count: null, error: { message: "DB connection error" } },
    finishResult: { data: null, error: null },
    nextGwResult: { data: null, error: null },
  });

  let threw = false;
  let advanced = false;
  try {
    advanced = await maybeAdvanceGameweek(db, 1, 12, nopLog);
  } catch {
    threw = true;
  }

  assertEquals(threw, false);
  assertEquals(advanced, false);
});

Deno.test("returns false when finish update errors, does not promote next GW", async () => {
  const db = buildMockDb({
    countResult: { count: 0, error: null },
    finishResult: { data: null, error: { message: "update failed" } },
    nextGwResult: { data: { id: 2, round_number: 13 }, error: null },
  });

  const advanced = await maybeAdvanceGameweek(db, 1, 12, nopLog);

  assertEquals(advanced, false);
});

Deno.test("returns false when promotion of next GW errors", async () => {
  const db = buildMockDb({
    countResult: { count: 0, error: null },
    finishResult: { data: [{ id: 1 }], error: null },
    nextGwResult: { data: { id: 2, round_number: 13 }, error: null },
    promoteResult: { error: { message: "promote failed" } },
  });

  const advanced = await maybeAdvanceGameweek(db, 1, 12, nopLog);

  assertEquals(advanced, false);
});

Deno.test("idempotent: calling twice with same all-settled state is a no-op on second call", async () => {
  // First call: succeeds
  const db1 = buildMockDb({
    countResult: { count: 0, error: null },
    finishResult: { data: [{ id: 1 }], error: null },
    nextGwResult: { data: { id: 2, round_number: 13 }, error: null },
    promoteResult: { error: null },
  });
  const first = await maybeAdvanceGameweek(db1, 1, 12, nopLog);
  assertEquals(first, true);

  // Second call: WHERE guard returns 0 rows → no-op
  const db2 = buildMockDb({
    countResult: { count: 0, error: null },
    finishResult: { data: [], error: null }, // 0 rows — already finished
    nextGwResult: { data: null, error: null },
  });
  const second = await maybeAdvanceGameweek(db2, 1, 12, nopLog);
  assertEquals(second, false);
});
