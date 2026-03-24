// Lightweight word-list content moderation.
// Whole-word matching only (\b boundaries) to avoid false positives.
// Football banter terms like "killing", "destroyed", "smashed" are NOT included.

const PROFANITY_LIST: string[] = [
  // Profanity
  "fuck", "fucking", "fucker", "shit", "shitty", "bullshit",
  "ass", "asshole", "bitch", "bastard", "dick", "dickhead",
  "cock", "cunt", "damn", "piss", "slut", "whore",
  "wanker", "twat", "bollocks", "tosser", "bellend",
  // Racial slurs
  "nigger", "nigga", "chink", "gook", "kike", "spic",
  "wetback", "beaner", "paki", "raghead", "towelhead",
  // Homophobic slurs
  "faggot", "fag", "dyke", "tranny",
  // Ableist slurs
  "retard", "retarded", "spastic", "spaz",
  // Hate speech
  "nazi", "hitler", "genocide", "ethnic cleansing",
  // Sexual
  "blowjob", "handjob", "porn", "pornography",
  "dildo", "vagina", "penis",
  // Misc offensive
  "cracker", "honky", "inbred", "scumbag",
];

// Pre-compile regex patterns for performance
const PATTERNS: RegExp[] = PROFANITY_LIST.map(
  (word) =>
    new RegExp(
      `\\b${word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`,
      "i",
    ),
);

export interface ModerationResult {
  valid: boolean;
  field?: string;
  reason?: string;
}

/**
 * Check a single string against the profanity word list.
 * Returns true if profanity is found.
 */
export function containsProfanity(text: string): boolean {
  return PATTERNS.some((pattern) => pattern.test(text));
}

/**
 * Validate league name and/or description.
 * Returns { valid: true } or { valid: false, field, reason }.
 */
export function validateLeagueContent(
  name?: string,
  description?: string,
): ModerationResult {
  if (name && containsProfanity(name)) {
    return {
      valid: false,
      field: "name",
      reason: "This name contains inappropriate language",
    };
  }
  if (description && containsProfanity(description)) {
    return {
      valid: false,
      field: "description",
      reason: "This description contains inappropriate language",
    };
  }
  return { valid: true };
}
