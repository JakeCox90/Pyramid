-- Migration: 20260327_rate_limits
-- Description: Per-user rate limiting infrastructure for Edge Functions.
--              Sliding window counter stored in DB (no Redis dependency).
-- ROLLBACK: DROP FUNCTION IF EXISTS public.check_rate_limit; DROP FUNCTION IF EXISTS public.cleanup_expired_rate_limits; DROP TABLE IF EXISTS public.rate_limits;

-- ─── Table ──────────────────────────────────────────────────────────────────────

create table if not exists public.rate_limits (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null,
  function_name   text not null,
  request_count   integer not null default 1,
  window_start    timestamptz not null,
  created_at      timestamptz not null default now(),

  unique (user_id, function_name, window_start)
);

comment on table public.rate_limits is
  'Per-user, per-function rate limit counters. Each row represents a time window. '
  'Rows are ephemeral and cleaned up by cleanup_expired_rate_limits().';

create index if not exists rate_limits_user_fn_idx
  on public.rate_limits(user_id, function_name);
create index if not exists rate_limits_window_idx
  on public.rate_limits(window_start);

-- No RLS needed — this table is only accessed via service-role from Edge Functions.
alter table public.rate_limits enable row level security;

-- ─── Atomic rate limit check ────────────────────────────────────────────────────

create or replace function public.check_rate_limit(
  p_user_id        uuid,
  p_function_name  text,
  p_max_requests   integer,
  p_window_seconds integer
)
returns table (
  allowed        boolean,
  current_count  integer,
  retry_after_s  integer
)
language plpgsql
security definer
as $$
declare
  v_window_start  timestamptz;
  v_count         integer;
  v_remaining_s   integer;
begin
  -- Compute the start of the current window (truncated to window_seconds boundaries).
  -- This gives us fixed windows aligned to epoch, which is simpler than true sliding
  -- windows but sufficient for abuse prevention.
  v_window_start := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );

  -- Upsert: increment the counter for this user+function+window.
  insert into public.rate_limits (user_id, function_name, request_count, window_start)
  values (p_user_id, p_function_name, 1, v_window_start)
  on conflict (user_id, function_name, window_start)
  do update set request_count = rate_limits.request_count + 1
  returning rate_limits.request_count into v_count;

  -- Compute seconds remaining in the current window.
  v_remaining_s := greatest(1, p_window_seconds - extract(epoch from (now() - v_window_start))::integer);

  if v_count > p_max_requests then
    return query select false, v_count, v_remaining_s;
  else
    return query select true, v_count, 0;
  end if;
end;
$$;

comment on function public.check_rate_limit is
  'Atomically checks and increments a per-user, per-function rate limit counter. '
  'Returns (allowed, current_count, retry_after_s). Uses fixed time windows.';

-- ─── Cleanup function ───────────────────────────────────────────────────────────
-- Call periodically (e.g. from a cron or after each request) to prevent table bloat.

create or replace function public.cleanup_expired_rate_limits()
returns integer
language plpgsql
security definer
as $$
declare
  v_deleted integer;
begin
  delete from public.rate_limits
  where window_start < now() - interval '2 hours'
  returning 1 into v_deleted;

  return coalesce(v_deleted, 0);
end;
$$;

comment on function public.cleanup_expired_rate_limits is
  'Deletes rate_limits rows older than 2 hours. Call periodically to prevent bloat.';
