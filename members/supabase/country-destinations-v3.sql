-- Side Income Lab: country-specific offer destinations. Safe to rerun.
-- Execute in Supabase SQL Editor while Surveoo is still draft.
create table if not exists public.opportunity_destinations (
 opportunity_id uuid not null references public.opportunities(id) on delete cascade,
 country_code text not null check(country_code in ('ZW','ZA','GB','US','CA')),
 destination_url text not null check(destination_url ~ '^https://'),
 created_at timestamptz not null default now(),
 primary key(opportunity_id,country_code)
);
alter table public.opportunity_destinations enable row level security;
drop policy if exists "eligible country destination read" on public.opportunity_destinations;
create policy "eligible country destination read" on public.opportunity_destinations
 for select to authenticated using (
 exists(select 1 from public.opportunities o where o.id=opportunity_id and o.status='published' and country_code=any(o.countries_allowed))
 and exists(select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.country_code=opportunity_destinations.country_code)
);
-- Block exposure of the legacy single URL field to authenticated clients.
-- Postgres column grants are required because RLS is row-level, not column-level.
revoke select on public.opportunities from authenticated;
grant select(id,title,description,category,countries_allowed,status,created_at,updated_at) on public.opportunities to authenticated;
grant select on public.opportunity_destinations to authenticated;
-- Seed destinations for the existing Surveoo draft.
insert into public.opportunity_destinations(opportunity_id,country_code,destination_url)
select o.id,v.country_code,v.destination_url from public.opportunities o
cross join (values
 ('ZW','https://afflat3e3.com/trk/lnk/AB26B4B6-250F-4E98-BB8E-91B1EBA7F71D/?o=31078&c=918277&a=583304&k=DBCE17B76324496C7A10BA2550087977&l=36077&s1=members&s2=zw&s3=vault&s4=surveoo01&s5=app'),
 ('ZA','https://afflat3e1.com/trk/lnk/AB26B4B6-250F-4E98-BB8E-91B1EBA7F71D/?o=31078&c=918277&a=583304&k=DBCE17B76324496C7A10BA2550087977&l=36077&s1=members&s2=za&s3=vault&s4=surveoo01&s5=app'),
 ('GB','https://afflat3e1.com/trk/lnk/AB26B4B6-250F-4E98-BB8E-91B1EBA7F71D/?o=31078&c=918277&a=583304&k=DBCE17B76324496C7A10BA2550087977&l=36077&s1=members&s2=gb&s3=vault&s4=surveoo01&s5=app'),
 ('US','https://afflat3e1.com/trk/lnk/AB26B4B6-250F-4E98-BB8E-91B1EBA7F71D/?o=31078&c=918277&a=583304&k=DBCE17B76324496C7A10BA2550087977&l=36077&s1=members&s2=us&s3=vault&s4=surveoo01&s5=app'),
 ('CA','https://afflat3e1.com/trk/lnk/AB26B4B6-250F-4E98-BB8E-91B1EBA7F71D/?o=31078&c=918277&a=583304&k=DBCE17B76324496C7A10BA2550087977&l=36077&s1=members&s2=ca&s3=vault&s4=surveoo01&s5=app')
) as v(country_code,destination_url)
where o.title='Surveoo — Paid Surveys' and o.status='draft'
on conflict(opportunity_id,country_code) do update set destination_url=excluded.destination_url;
-- Preserve draft status until traffic classification and final landing-page checks are complete.
select o.title,o.status,d.country_code,d.destination_url
from public.opportunities o join public.opportunity_destinations d on d.opportunity_id=o.id
where o.title='Surveoo — Paid Surveys' order by d.country_code;
