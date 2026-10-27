-- V2 additive migration: saves and administrator-managed opportunity links.
alter table public.opportunities add column if not exists destination_url text;
alter table public.opportunities add column if not exists updated_at timestamptz not null default now();
create table if not exists public.saved_opportunities(
  user_id uuid not null references auth.users(id) on delete cascade,
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key(user_id,opportunity_id)
);
alter table public.saved_opportunities enable row level security;
create policy "saved read own" on public.saved_opportunities for select to authenticated using((select auth.uid())=user_id);
create policy "saved insert own" on public.saved_opportunities for insert to authenticated with check((select auth.uid())=user_id);
create policy "saved delete own" on public.saved_opportunities for delete to authenticated using((select auth.uid())=user_id);
-- Do not create client-side write access to opportunities. Admin editing requires a separate privileged server workflow.
