// Shared APNs HTTP/2 push notification utility.
// Used by send-notification to deliver pushes to individual device tokens.
//
// Required environment variables:
//   APNS_KEY_ID        — 10-char APNs key ID
//   APNS_TEAM_ID       — 10-char Apple Team ID
//   APNS_AUTH_KEY      — contents of the .p8 auth key file (PEM format)
//   APNS_BUNDLE_ID     — app bundle identifier (e.g. com.pyramid.app)
//   APNS_ENVIRONMENT   — "sandbox" | "production"

export interface ApnsPayload {
  aps: {
    alert: { title?: string; body: string };
    sound?: string;
    badge?: number;
    "content-available"?: number;
  };
  screen?: string; // deep link screen name for iOS routing
  [key: string]: unknown;
}

export interface ApnsResult {
  token: string;
  success: boolean;
  shouldDeleteToken: boolean; // true on APNs 410 (device unregistered)
}

// ─── JWT signing ──────────────────────────────────────────────────────────────

/**
 * Converts a PEM-formatted EC private key string to a CryptoKey using
 * the Web Crypto API available in Deno.
 */
async function importApnsKey(pem: string): Promise<CryptoKey> {
  // Strip PEM header/footer and whitespace, decode base64 to DER bytes
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/-----BEGIN EC PRIVATE KEY-----/, "")
    .replace(/-----END EC PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");

  const derBytes = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));

  return await crypto.subtle.importKey(
    "pkcs8",
    derBytes,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

/**
 * Creates a signed APNs JWT bearer token.
 * APNs tokens expire after 60 minutes — for simplicity we generate a fresh
 * token per request. For high-volume usage, callers should cache and reuse.
 */
async function createApnsJwt(keyId: string, teamId: string, authKey: string): Promise<string> {
  const header = { alg: "ES256", kid: keyId };
  const claims = { iss: teamId, iat: Math.floor(Date.now() / 1000) };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");

  const signingInput = `${encode(header)}.${encode(claims)}`;
  const signingBytes = new TextEncoder().encode(signingInput);

  const key = await importApnsKey(authKey);
  const signatureBuffer = await crypto.subtle.sign(
    { name: "ECDSA", hash: { name: "SHA-256" } },
    key,
    signingBytes,
  );

  const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");

  return `${signingInput}.${signature}`;
}

// ─── Main export ──────────────────────────────────────────────────────────────

/**
 * Sends an APNs push notification to a single device token.
 * Uses APNs HTTP/2 API with JWT authentication.
 * Returns ApnsResult — never throws (fire-and-forget safe).
 */
export async function sendApnsNotification(
  token: string,
  payload: ApnsPayload,
): Promise<ApnsResult> {
  const failure = (shouldDeleteToken: boolean): ApnsResult => ({
    token,
    success: false,
    shouldDeleteToken,
  });

  try {
    const keyId = Deno.env.get("APNS_KEY_ID");
    const teamId = Deno.env.get("APNS_TEAM_ID");
    const authKey = Deno.env.get("APNS_AUTH_KEY");
    const bundleId = Deno.env.get("APNS_BUNDLE_ID");
    const environment = Deno.env.get("APNS_ENVIRONMENT") ?? "sandbox";

    if (!keyId || !teamId || !authKey || !bundleId) {
      console.error("APNs: missing required environment variables");
      return failure(false);
    }

    const host =
      environment === "production"
        ? "https://api.push.apple.com"
        : "https://api.sandbox.push.apple.com";

    const url = `${host}/3/device/${token}`;
    const jwt = await createApnsJwt(keyId, teamId, authKey);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (response.status === 200) {
      return { token, success: true, shouldDeleteToken: false };
    }

    if (response.status === 410) {
      // Device is no longer registered — caller should delete this token
      console.warn(`APNs 410 for token ${token.slice(0, 8)}... — device unregistered`);
      return failure(true);
    }

    // Any other error (400, 403, 429, 500, etc.)
    const body = await response.text().catch(() => "");
    console.error(`APNs error ${response.status} for token ${token.slice(0, 8)}...: ${body}`);
    return failure(false);
  } catch (err) {
    console.error(`APNs unexpected error for token ${token.slice(0, 8)}...:`, err);
    return failure(false);
  }
}
