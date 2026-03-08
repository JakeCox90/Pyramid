-- Migration: notification tables for PYR-33 push notifications
-- device_tokens: stores APNs tokens per user (one user can have multiple devices)
-- notification_preferences: per-user opt-in/out controls

-- device_tokens table
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null default 'ios',
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique(user_id, token)  -- one row per user+device combination
);

-- RLS: users manage only their own tokens
alter table public.device_tokens enable row level security;
create policy "Users manage own device tokens" on public.device_tokens
  for all using (auth.uid() = user_id);

-- notification_preferences table
create table public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  deadline_reminders boolean not null default true,
  pick_locked boolean not null default true,
  result_alerts boolean not null default true,
  winnings_alerts boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.notification_preferences enable row level security;
create policy "Users manage own notification preferences" on public.notification_preferences
  for all using (auth.uid() = user_id);
