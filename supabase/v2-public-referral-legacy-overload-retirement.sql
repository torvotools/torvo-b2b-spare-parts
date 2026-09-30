-- TORVO V2 PUBLIC REFERRAL LEGACY OVERLOAD RETIREMENT
-- Final public flow requires a verified Dealer selection and lead-source-aware 7-argument RPC.
-- Retire the older 6-argument overload so callers cannot bypass the canonical referral integrity contract.
drop function if exists public.public_create_customer_referral(text,text,text,uuid,uuid,boolean);

do $$
begin
  if to_regprocedure('public.public_create_customer_referral(text,text,text,uuid,uuid,boolean)') is not null then
    raise exception 'LEGACY PUBLIC CUSTOMER REFERRAL OVERLOAD STILL INSTALLED';
  end if;
  if to_regprocedure('public.public_create_customer_referral(text,text,text,uuid,uuid,boolean,text)') is null then
    raise exception 'CANONICAL PUBLIC CUSTOMER REFERRAL RPC MISSING';
  end if;
end $$;
