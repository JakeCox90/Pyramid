// Shared notification utility for Edge Functions.
// Looks up APNs tokens for a user, checks notification preferences,
// sends to all devices, and cleans up stale tokens on APNs 410.
//
// Fire-and-forget: never throws — all errors are logged and swallowed.
// Callers must wrap in try/catch as an extra safety net.

import { getServiceClient } from "./supabase.ts";
import { sendApnsNotification } from "./apns.ts";
import type { ApnsPayload } from "./apns.ts";

// ─── Types ────────────────────────────────────────────────────────────────────

export type NotificationTemplate =
  | "deadline_reminder"
  | "pick_locked"
  | "result_survived"
  | "result_eliminated"
  | "result_void"
  | "mass_elimination"
  | "round_complete_winner"
  | "round_complete_placed"
  | "round_complete_no_prize"
  | "winnings_withdrawable";

export interface SendNotificationParams {
  userId: string;
  template: NotificationTemplate;
  data: Record<string, string | number>; // template variables
}

// ─── Preference key lookup ────────────────────────────────────────────────────

type PreferenceKey = "deadline_reminders" | "pick_locked" | "result_alerts" | "winnings_alerts";

function preferenceKeyFor(template: NotificationTemplate): PreferenceKey {
  switch (template) {
    case "deadline_reminder":
    case "pick_locked":
      return "deadline_reminders";
    case "result_survived":
    case "result_eliminated":
    case "result_void":
    case "mass_elimination":
    case "round_complete_winner":
    case "round_complete_placed":
    case "round_complete_no_prize":
      return "result_alerts";
    case "winnings_withdrawable":
      return "winnings_alerts";
  }
}

// ─── Template rendering ───────────────────────────────────────────────────────

interface TemplateOutput {
  body: string;
  screen: string;
}

/**
 * Renders a notification template using the provided data map.
 * Variable substitution: {key} → data[key].
 */
export function renderTemplate(
  template: NotificationTemplate,
  data: Record<string, string | number>,
): TemplateOutput {
  const sub = (str: string) =>
    str.replace(/\{(\w+)\}/g, (_, key) => String(data[key] ?? `{${key}}`));

  switch (template) {
    case "deadline_reminder":
      return {
        body: sub("Deadline in 1 hour — pick your team for GW{gameweek} before kick-off"),
        screen: "picks",
      };
    case "pick_locked":
      return {
        body: sub("{teamName} vs {opponent} has kicked off — your pick is locked. Good luck!"),
        screen: "standings",
      };
    case "result_survived":
      return {
        body: sub("Full time: {teamName} {score} — you survived GW{gameweek}!"),
        screen: "standings",
      };
    case "result_eliminated":
      return {
        body: sub(
          "Full time: {teamName} {score} — you've been eliminated from {leagueName}",
        ),
        screen: "standings",
      };
    case "result_void":
      return {
        body: sub("{teamName}'s match was postponed — your pick is voided. Repick now."),
        screen: "picks",
      };
    case "mass_elimination":
      return {
        body: sub(
          "Mass elimination in {leagueName} — everyone survives! GW{gameweek} picks count as used.",
        ),
        screen: "standings",
      };
    case "round_complete_winner":
      return {
        body: sub(
          "You won £{amount} in {leagueName}! Your winnings are available to play.",
        ),
        screen: "wallet",
      };
    case "round_complete_placed":
      return {
        body: sub(
          "Round over — you finished {position} in {leagueName} and won £{amount}.",
        ),
        screen: "standings",
      };
    case "round_complete_no_prize":
      return {
        body: sub("Round over in {leagueName} — well played. Join a new round?"),
        screen: "standings",
      };
    case "winnings_withdrawable":
      return {
        body: sub("£{amount} is now available to withdraw from your wallet."),
        screen: "wallet",
      };
  }
}

// ─── Main export ──────────────────────────────────────────────────────────────

/**
 * Sends a push notification to all devices registered for userId.
 * Respects notification_preferences — skips send if the relevant preference
 * is disabled. Deletes device tokens that return APNs 410.
 * Never throws — all errors are logged and swallowed.
 */
export async function sendNotification(params: SendNotificationParams): Promise<void> {
  const { userId, template, data } = params;

  try {
    const db = getServiceClient();
    const prefKey = preferenceKeyFor(template);

    // 1. Check notification preferences
    const { data: prefs } = await db
      .from("notification_preferences")
      .select(prefKey)
      .eq("user_id", userId)
      .maybeSingle();

    // If a preferences row exists and the relevant preference is explicitly false, skip
    if (prefs !== null && prefs !== undefined && prefs[prefKey] === false) {
      console.log(`sendNotification: user ${userId} has ${prefKey} disabled — skipping`);
      return;
    }

    // 2. Fetch device tokens for this user
    const { data: tokenRows, error: tokenErr } = await db
      .from("device_tokens")
      .select("token")
      .eq("user_id", userId);

    if (tokenErr) {
      console.error(`sendNotification: failed to fetch tokens for user ${userId}:`, tokenErr);
      return;
    }

    const tokens = (tokenRows ?? []).map((r: { token: string }) => r.token);
    if (tokens.length === 0) {
      console.log(`sendNotification: no device tokens for user ${userId}`);
      return;
    }

    // 3. Render the template
    const { body, screen } = renderTemplate(template, data);

    const payload: ApnsPayload = {
      aps: {
        alert: { body },
        sound: "default",
      },
      screen,
    };

    // 4. Send to each device token; collect tokens to delete on 410
    const tokensToDelete: string[] = [];

    await Promise.all(
      tokens.map(async (token: string) => {
        const result = await sendApnsNotification(token, payload);
        if (result.shouldDeleteToken) {
          tokensToDelete.push(token);
        }
      }),
    );

    // 5. Clean up stale tokens
    if (tokensToDelete.length > 0) {
      const { error: deleteErr } = await db
        .from("device_tokens")
        .delete()
        .eq("user_id", userId)
        .in("token", tokensToDelete);

      if (deleteErr) {
        console.error(
          `sendNotification: failed to delete stale tokens for user ${userId}:`,
          deleteErr,
        );
      } else {
        console.log(
          `sendNotification: deleted ${tokensToDelete.length} stale token(s) for user ${userId}`,
        );
      }
    }
  } catch (err) {
    // Fire-and-forget: log but never propagate
    console.error(`sendNotification: unexpected error for user ${userId}:`, err);
  }
}
