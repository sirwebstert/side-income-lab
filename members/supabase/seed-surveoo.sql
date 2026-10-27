-- Execute once in Supabase SQL Editor to publish the first researched listing.
-- Confirm campaign 31078 is still active, supports ZA/ZW and allows this traffic before making live.
insert into public.opportunities(title,description,category,countries_allowed,status)
select 'Surveoo — Paid Surveys','Explore paid survey opportunities. Availability, eligibility and rewards vary. Registration does not guarantee earnings.','Paid Surveys',array['ZA','ZW'],'draft'
where not exists(select 1 from public.opportunities where title='Surveoo — Paid Surveys');
-- When campaign terms and destination have been revalidated:
-- update public.opportunities set status='published' where title='Surveoo — Paid Surveys';
