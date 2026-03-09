// Shared alerting utility for Edge Functions.
// Sends alerts to Slack when ALERT_SLACK_WEBHOOK_URL is configured.
// Fire-and-forget: alert failures never break the calling function.

/**
 * Send an alert to Slack. No-op if ALERT_SLACK_WEBHOOK_URL is not set.
 * Always fire-and-forget — errors are logged but never thrown.
 */
export async function alertSlack(
  text: string,
  context?: Record<string, unknown>,
): Promise<void> {
  const webhookUrl = Deno.env.get("ALERT_SLACK_WEBHOOK_URL");
  if (!webhookUrl) return;

  const payload = context
    ? `${text}\n\`\`\`${JSON.stringify(context, null, 2)}\`\`\``
    : text;

  try {
    await fetch(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: payload }),
    });
  } catch (err) {
    // Fire-and-forget: never let alert failures break the calling function
    console.error(`alertSlack failed: ${err}`);
  }
}
