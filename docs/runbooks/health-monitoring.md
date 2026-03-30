# Health Monitoring Runbook

## Health Check Endpoint

`GET /health` — service-role authenticated, returns structured JSON.

### Response Format

```json
{
  "status": "healthy" | "degraded" | "unhealthy",
  "checks": {
    "database":       { "status": "pass"|"warn"|"fail", "latency_ms": 12, "message": "..." },
    "api_football":   { "status": "pass"|"warn"|"fail", "latency_ms": 200, "message": "..." },
    "gameweek_data":  { "status": "pass"|"warn"|"fail", "latency_ms": 15, "message": "..." },
    "settlement":     { "status": "pass"|"warn"|"fail", "latency_ms": 20, "message": "..." }
  },
  "timestamp": "2026-03-30T10:00:00.000Z",
  "version": "dev"
}
```

- **healthy** (200): All checks pass
- **degraded** (200): One or more warnings (e.g. quota >80%, no current gameweek)
- **unhealthy** (503): One or more failures (DB down, API-Football unreachable)

### Calling the Endpoint

```bash
# Dev
curl -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  https://qvmzmeizluqcdkcjsqyd.supabase.co/functions/v1/health

# Prod
curl -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  https://cracvbokmvryhhclzxxw.supabase.co/functions/v1/health
```

## Checks Explained

| Check | What it does | Warn condition | Fail condition |
|-------|-------------|----------------|----------------|
| `database` | `SELECT` from gameweeks | — | Query error |
| `api_football` | Calls `/status` endpoint, checks quota | Quota >80% | Timeout (5s) or HTTP error |
| `gameweek_data` | Verifies current GW exists with fixtures | No current GW or 0 fixtures | Query error |
| `settlement` | Checks for unsettled FT picks | Pending picks with FT results for >6h | Query error |

## External Monitoring Setup

### Recommended: BetterStack (free tier)

1. Create account at https://betterstack.com
2. Add a new monitor:
   - **URL:** `https://cracvbokmvryhhclzxxw.supabase.co/functions/v1/health`
   - **Method:** GET
   - **Headers:** `Authorization: Bearer <prod-service-role-key>`
   - **Check interval:** 5 minutes
   - **Expected status:** 200
   - **Confirmation period:** 2 minutes (avoid false alarms)
3. Configure alerts:
   - **Email:** jake@pyramidapp.co (or team distribution list)
   - **Slack webhook:** (configure when Slack workspace is set up)
4. Add a status page (optional): public uptime dashboard for transparency

### Alternative: UptimeRobot (free tier, 50 monitors)

Same config as above — UptimeRobot supports custom headers and status code checks.

## Alert Response Playbook

### Database failure
1. Check Supabase Dashboard → Database → Health
2. If Supabase outage: check https://status.supabase.com
3. If our DB: check for long-running queries, connection pool exhaustion

### API-Football failure
1. Check https://dashboard.api-football.com for status
2. If quota exhausted: reduce polling frequency or upgrade plan
3. If API down: live scores will be stale — settlement will catch up when API returns

### Settlement delay
1. Check if `settle-picks` Edge Function has errors in Supabase logs
2. Manually trigger: `curl -X POST -H "Authorization: Bearer $KEY" .../settle-picks`
3. Check `settlement_log` for the latest entry and any error messages

### Gameweek data missing
1. Run `sync-fixtures` manually to populate fixtures
2. Verify `is_current` flag is set on the correct gameweek in the `gameweeks` table
