-- Website leads backend for pravovyi-lider-frontend
-- Isolated from the existing legal-aid domain tables.

create table if not exists public.website_leads (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  phone text not null check (char_length(phone) between 7 and 40),
  email text null check (email is null or char_length(email) <= 320),
  city text null check (city is null or char_length(city) <= 120),
  message text null check (message is null or char_length(message) <= 2000),
  source text not null default 'website' check (char_length(source) between 1 and 80),
  status text not null default 'new' check (status in ('new','contacted','closed','spam')),
  ip_hash text null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists website_leads_created_at_idx
  on public.website_leads (created_at desc);

create index if not exists website_leads_status_idx
  on public.website_leads (status, created_at desc);

alter table public.website_leads enable row level security;

revoke all on table public.website_leads from anon;
grant select, update on table public.website_leads to authenticated;

drop policy if exists website_leads_staff_select on public.website_leads;
create policy website_leads_staff_select
on public.website_leads
for select
to authenticated
using (
  exists (
    select 1
    from public.organization_members om
    where om.user_id = auth.uid()
      and om.active = true
  )
);

drop policy if exists website_leads_staff_update on public.website_leads;
create policy website_leads_staff_update
on public.website_leads
for update
to authenticated
using (
  exists (
    select 1
    from public.organization_members om
    where om.user_id = auth.uid()
      and om.active = true
  )
)
with check (
  exists (
    select 1
    from public.organization_members om
    where om.user_id = auth.uid()
      and om.active = true
  )
);

create table if not exists private.website_lead_rate_limits (
  ip_hash text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now()
);

create or replace function private.consume_website_lead_rate_limit(
  p_ip_hash text,
  p_limit integer default 6,
  p_window_seconds integer default 3600
)
returns boolean
language plpgsql
security definer
set search_path = private, public
as $$
declare
  v_now timestamptz := now();
  v_allowed boolean := false;
begin
  insert into private.website_lead_rate_limits (ip_hash, window_started_at, request_count, updated_at)
  values (p_ip_hash, v_now, 1, v_now)
  on conflict (ip_hash) do update
    set request_count = case
          when private.website_lead_rate_limits.window_started_at < v_now - make_interval(secs => p_window_seconds)
            then 1
          else private.website_lead_rate_limits.request_count + 1
        end,
        window_started_at = case
          when private.website_lead_rate_limits.window_started_at < v_now - make_interval(secs => p_window_seconds)
            then v_now
          else private.website_lead_rate_limits.window_started_at
        end,
        updated_at = v_now
  returning request_count <= p_limit into v_allowed;

  return v_allowed;
end;
$$;

revoke all on function private.consume_website_lead_rate_limit(text, integer, integer) from public, anon, authenticated;
