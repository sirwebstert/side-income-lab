-- Offer click analytics v1. Run once in Supabase SQL Editor before deploying the route update.
create table if not exists public.offer_clicks (
 id bigint generated always as identity primary key,
 opportunity_id uuid not null references public.opportunities(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 country_code text not null,
 clicked_at timestamptz not null default now()
);
create index if not exists offer_clicks_date_idx on public.offer_clicks(clicked_at desc);
create index if not exists offer_clicks_offer_idx on public.offer_clicks(opportunity_id,clicked_at desc);
alter table public.offer_clicks enable row level security;
revoke all on public.offer_clicks from anon,authenticated;
-- No direct client inserts or reads: authenticated server route uses a constrained RPC.
create or replace function public.record_offer_click(p_opportunity_id uuid,p_country_code text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Unauthenticated' using errcode='28000'; end if;
 if not exists (
  select 1 from public.profiles p
  join public.opportunities o on o.id=p_opportunity_id
  join public.opportunity_destinations d on d.opportunity_id=o.id and d.country_code=p.country_code
  where p.user_id=auth.uid() and p.country_code=p_country_code
    and o.status='published' and p.country_code=any(o.countries_allowed)
 ) then raise exception 'Offer not eligible' using errcode='42501'; end if;
 insert into public.offer_clicks(opportunity_id,user_id,country_code)
 values(p_opportunity_id,auth.uid(),p_country_code);
end;
$$;
revoke all on function public.record_offer_click(uuid,text) from public;
grant execute on function public.record_offer_click(uuid,text) to authenticated;

create or replace function public.admin_offer_click_summary()
returns table(opportunity_id uuid,country_code text,clicks bigint,unique_members bigint)
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.is_admin() then raise exception 'Forbidden' using errcode='42501'; end if;
 return query select c.opportunity_id,c.country_code,count(*)::bigint,count(distinct c.user_id)::bigint
 from public.offer_clicks c group by c.opportunity_id,c.country_code;
end;
$$;
revoke all on function public.admin_offer_click_summary() from public;
grant execute on function public.admin_offer_click_summary() to authenticated;
