import { getServiceClient, serviceHeaders } from "../_shared/supabase.ts";
import { createLogger } from "../_shared/logger.ts";
import { alertSlack } from "../_shared/alert.ts";
import { buildStoryContext } from "./analysis.ts";
import { buildPrompt, parseStoryOutput } from "./prompts.ts";

interface RequestBody {
  leagueId: string;
  gameweek: number;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!serviceKey || !authHeader.includes(serviceKey)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const log = createLogger("generate-gameweek-story", req);

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const { leagueId, gameweek } = body;
  if (!leagueId || !gameweek) {
    return json({ error: "leagueId and gameweek required" }, 400);
  }

  const idempotencyKey = `${leagueId}_${gameweek}`;
  const db = getServiceClient();

  try {
    // 0. Early idempotency check — avoid LLM cost on duplicate calls
    const { data: existing } = await db
      .from("gameweek_stories")
      .select("id")
      .eq("idempotency_key", idempotencyKey)
      .limit(1);

    if (existing && existing.length > 0) {
      log.info("Story already exists (early idempotency check)", { idempotencyKey });
      return json({ status: "already_exists" }, 200);
    }

    // 1. Build story context from settled data
    log.info("Building story context", { leagueId, gameweek });
    const ctx = await buildStoryContext(db, leagueId, gameweek);

    // 2. Generate editorial via LLM
    log.info("Generating editorial", { eliminations: ctx.eliminations.length, survivors: ctx.survivors.length });
    const prompt = buildPrompt(ctx);

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    let headline: string | null = null;
    let storyBody: string | null = null;

    if (anthropicKey) {
      try {
        const llmResponse = await fetch("https://api.anthropic.com/v1/messages", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-api-key": anthropicKey,
            "anthropic-version": "2023-06-01",
          },
          body: JSON.stringify({
            model: "claude-haiku-4-5-20251001",
            max_tokens: 256,
            messages: [{ role: "user", content: prompt }],
          }),
        });

        if (llmResponse.ok) {
          const llmData = await llmResponse.json();
          const rawText = llmData.content?.[0]?.text ?? "";
          const parsed = parseStoryOutput(rawText);
          if (parsed) {
            headline = parsed.headline;
            storyBody = parsed.body;
          } else {
            log.warn("LLM returned incomplete JSON — missing headline or body");
          }
          log.info("Editorial generated", { headline });
        } else {
          log.warn("LLM API returned non-OK", { status: llmResponse.status });
        }
      } catch (llmErr) {
        log.warn("LLM generation failed, proceeding without editorial", { error: String(llmErr) });
      }
    } else {
      log.warn("ANTHROPIC_API_KEY not set, skipping editorial generation");
    }

    // 3. Write story row (idempotent) — use gameweek_id per migration schema
    const { error: insertError } = await db.from("gameweek_stories").insert({
      league_id: leagueId,
      gameweek_id: gameweek,
      headline,
      body: storyBody,
      wildcard_pick_id: ctx.wildcardPick?.pickId ?? null,
      upset_fixture_id: ctx.upsetFixture?.fixtureId ?? null,
      is_mass_elimination: ctx.isMassElimination,
      idempotency_key: idempotencyKey,
    });

    if (insertError) {
      if (insertError.code === "23505") {
        log.info("Story already exists (idempotent no-op)", { idempotencyKey });
        return json({ status: "already_exists" }, 200);
      }
      throw insertError;
    }

    log.complete("ok", { leagueId, gameweek, hasEditorial: !!headline });
    return json({ status: "created", headline, hasEditorial: !!headline }, 201);
  } catch (err) {
    log.error("Story generation failed", err, { leagueId, gameweek });
    const safeError = String(err?.message || "Unknown error").substring(0, 200);
    await alertSlack("generate-gameweek-story failed", {
      leagueId,
      gameweek,
      error: safeError,
    });
    return json({ error: "Internal server error" }, 500);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: serviceHeaders(),
  });
}
