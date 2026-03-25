import { StoryContext } from "./analysis.ts";

export interface StoryOutput {
  headline: string;
  body: string;
}

export function buildPrompt(ctx: StoryContext): string {
  const elimNames = ctx.eliminations.map((e) =>
    e.isAutoEliminated ? `${e.displayName} (missed deadline)` : `${e.displayName} (picked ${e.teamName})`
  ).join(", ");

  const survNames = ctx.survivors.map((s) => `${s.displayName} (${s.teamName}: ${s.result})`).join(", ");

  const upsetLine = ctx.upsetFixture
    ? `Biggest upset: ${ctx.upsetFixture.homeTeam} ${ctx.upsetFixture.homeScore}–${ctx.upsetFixture.awayScore} ${ctx.upsetFixture.awayTeam} (${ctx.upsetFixture.eliminationCount} eliminated).`
    : "No major upsets this week.";

  const massElimLine = ctx.isMassElimination
    ? "MASS ELIMINATION occurred — every remaining player was eliminated, so ALL were reinstated per the rules."
    : "";

  return `You are the narrator of a Premier League Last Man Standing league called "${ctx.leagueName}".

Gameweek ${ctx.gameweek} has just finished. Here's what happened:

Players remaining before this GW: ${ctx.activeBeforeSettlement} of ${ctx.totalMembers}
Eliminated this week: ${ctx.eliminations.length > 0 ? elimNames : "Nobody — everyone survived."}
Survived this week: ${survNames || "Nobody (see mass elimination)."}
${upsetLine}
${massElimLine}

Write a short, punchy recap:
- "headline": a dramatic headline (max 5 words, no quotes)
- "body": a narrative paragraph (max 60 words) referencing specific players and events

Tone: witty, opinionated football banter. Like a group chat narrator who's watched every game. Use first names only. Be specific — never generic.

Respond with valid JSON only: {"headline": "...", "body": "..."}`;
}

export function parseStoryOutput(raw: string): StoryOutput | null {
  const cleaned = raw.replace(/```json?\n?/g, "").replace(/```/g, "").trim();
  const parsed = JSON.parse(cleaned);
  if (!parsed.headline || !parsed.body) return null;
  return {
    headline: String(parsed.headline).slice(0, 100),
    body: String(parsed.body).slice(0, 500),
  };
}
