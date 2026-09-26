-- Public-schema RPC callable only by the service role used inside the Edge Function.
-- It wraps the private rate-limit table without exposing it to browser clients.

create or replace function public.consume_website_lead_rate_limit(
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

revoke all on function public.consume_website_lead_rate_limit(text, integer, integer) from public, anon, authenticated;
grant execute on function public.consume_website_lead_rate_limit(text, integer, integer) to service_role;
