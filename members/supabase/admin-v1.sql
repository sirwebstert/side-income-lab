-- STEP 27: Run once in Supabase SQL Editor as project owner.
-- Admin membership is granted ONLY by privileged SQL, never by signup or user metadata.
create table if not exists public.admin_users (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
revoke all on public.admin_users from anon, authenticated;
grant select on public.admin_users to authenticated;
drop policy if exists "admin membership own read" on public.admin_users;
create policy "admin membership own read" on public.admin_users for select to authenticated using (user_id = (select auth.uid()));

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = '' as $$
 select exists(select 1 from public.admin_users where user_id = (select auth.uid()));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "admin read opportunities" on public.opportunities;
create policy "admin read opportunities" on public.opportunities for select to authenticated using ((select public.is_admin()));
drop policy if exists "admin create opportunities" on public.opportunities;
create policy "admin create opportunities" on public.opportunities for insert to authenticated with check ((select public.is_admin()));
drop policy if exists "admin edit opportunities" on public.opportunities;
create policy "admin edit opportunities" on public.opportunities for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists "admin delete opportunities" on public.opportunities;
create policy "admin delete opportunities" on public.opportunities for delete to authenticated using ((select public.is_admin()));

-- Existing country-based read policies remain unchanged.
drop policy if exists "admin read destinations" on public.opportunity_destinations;
create policy "admin read destinations" on public.opportunity_destinations for select to authenticated using ((select public.is_admin()));
drop policy if exists "admin create destinations" on public.opportunity_destinations;
create policy "admin create destinations" on public.opportunity_destinations for insert to authenticated with check ((select public.is_admin()));
drop policy if exists "admin edit destinations" on public.opportunity_destinations;
create policy "admin edit destinations" on public.opportunity_destinations for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists "admin delete destinations" on public.opportunity_destinations;
create policy "admin delete destinations" on public.opportunity_destinations for delete to authenticated using ((select public.is_admin()));

-- Admin-only aggregate member count; no member email/PII exposed.
create or replace function public.admin_member_count()
returns bigint language plpgsql stable security definer set search_path = '' as $$
begin
 if not public.is_admin() then raise exception 'Forbidden' using errcode='42501'; end if;
 return (select count(*) from public.profiles);
end;
$$;
revoke all on function public.admin_member_count() from public;
grant execute on function public.admin_member_count() to authenticated;

-- AFTER running this migration, grant yourself access using your actual auth user id:
-- insert into public.admin_users(user_id)
-- select id from auth.users where email = 'YOUR_SIGNUP_EMAIL'
-- on conflict (user_id) do nothing;
