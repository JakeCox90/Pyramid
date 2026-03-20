#!/usr/bin/env bash
# reset-dev.sh — Reset the Supabase dev environment (re-runs migrations + seed)
#
# Usage:
#   DEV_DATABASE_URL="postgresql://..." ./scripts/reset-dev.sh
#
# Safety: refuses to run unless the URL contains the dev project ID.

set -euo pipefail

DEV_PROJECT_ID="qvmzmeizluqcdkcjsqyd"

if [[ -z "${DEV_DATABASE_URL:-}" ]]; then
  echo "ERROR: DEV_DATABASE_URL is not set."
  echo "Export it first: export DEV_DATABASE_URL=\"postgresql://postgres.<project-ref>:...@aws-0-eu-west-2.pooler.supabase.com:5432/postgres\""
  exit 1
fi

if [[ "$DEV_DATABASE_URL" != *"$DEV_PROJECT_ID"* ]]; then
  echo "ERROR: DEV_DATABASE_URL does not contain the dev project ID ($DEV_PROJECT_ID)."
  echo "This safety check prevents accidental resets against production."
  exit 1
fi

echo "Resetting dev database (project: $DEV_PROJECT_ID)..."
supabase db reset --db-url "$DEV_DATABASE_URL"
echo "Done. Dev environment has been reset with fresh seed data."
