-- TORVO V2 PUBLIC LEAD SOURCE
-- ADDITIVE MIGRATION. RUN AFTER THE PUBLIC CUSTOMER/REFERRAL TABLES AND RPCS EXIST.
-- PURPOSE: PRESERVE WEBSITE / FACEBOOK / INSTAGRAM / YOUTUBE / WHATSAPP / EMAIL SOURCE WITHOUT EXPOSING PRIVATE DATA.

do $$ begin
  if to_regclass('public.customer_contacts') is not null then
    alter table public.customer_contacts add column if not exists lead_source text;
    alter table public.customer_contacts drop constraint if exists customer_contacts_lead_source_check;
    alter table public.customer_contacts add constraint customer_contacts_lead_source_check check(lead_source is null or lead_source in('WEBSITE','FACEBOOK','INSTAGRAM','YOUTUBE','WHATSAPP','EMAIL','OTHER'));
  end if;
end $$;

do $$ begin
  if to_regclass('public.customer_product_enquiries') is not null then
    alter table public.customer_product_enquiries add column if not exists lead_source text;
  end if;
  if to_regclass('public.product_requirements') is not null then
    alter table public.product_requirements add column if not exists lead_source text;
  end if;
  if to_regclass('public.customer_dealer_referrals') is not null then
    alter table public.customer_dealer_referrals add column if not exists lead_source text;
  end if;
  if to_regclass('public.repair_requests') is not null then
    alter table public.repair_requests add column if not exists lead_source text;
  end if;
end $$;

create or replace function public.torvo_normalize_public_lead_source(p_source text) returns text language sql immutable as $$
  select case upper(btrim(coalesce(p_source,'')))
    when 'FACEBOOK' then 'FACEBOOK' when 'INSTAGRAM' then 'INSTAGRAM' when 'YOUTUBE' then 'YOUTUBE'
    when 'WHATSAPP' then 'WHATSAPP' when 'EMAIL' then 'EMAIL' when 'OTHER' then 'OTHER' else 'WEBSITE' end
$$;
revoke all on function public.torvo_normalize_public_lead_source(text) from public;
grant execute on function public.torvo_normalize_public_lead_source(text) to anon,authenticated;

comment on function public.torvo_normalize_public_lead_source(text) is 'TORVO V2 allowlisted public lead-source normalizer. No private referrer URL is stored.';
