-- Run in a new Supabase project SQL editor; review before applying.
create table if not exists public.profiles (user_id uuid primary key references auth.users(id) on delete cascade,country_code text not null default 'ZA',display_name text,created_at timestamptz not null default now());
create table if not exists public.opportunities(id uuid primary key default gen_random_uuid(),title text not null,description text not null default '',category text not null,countries_allowed text[] not null default '{}',status text not null default 'draft' check(status in ('draft','published','archived')),created_at timestamptz not null default now());
create table if not exists public.consent_events(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,channel text not null,action text not null check(action in ('opt_in','opt_out')),policy_version text not null,source text not null,created_at timestamptz not null default now());
alter table public.profiles enable row level security;
alter table public.opportunities enable row level security;
alter table public.consent_events enable row level security;
create policy "profile select own" on public.profiles for select to authenticated using ((select auth.uid())=user_id);
create policy "profile insert own" on public.profiles for insert to authenticated with check ((select auth.uid())=user_id);
create policy "profile update own" on public.profiles for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "published opportunities read" on public.opportunities for select to authenticated using (status='published');
create policy "consent own read" on public.consent_events for select to authenticated using ((select auth.uid())=user_id);
-- Deliberately no client-side insert policy for consent_events until verified consent capture is implemented.
create or replace function public.create_profile() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(user_id,country_code) values(new.id,coalesce(new.raw_user_meta_data->>'country_code','ZA')); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.create_profile();
