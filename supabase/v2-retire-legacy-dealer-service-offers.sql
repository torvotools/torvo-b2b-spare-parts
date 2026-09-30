-- TORVO V2 RETIRE LEGACY DEALER SERVICE-OFFER RPC SURFACE
-- Current Dealer repair UI uses the device-bound customer repair requirement RPCs.
-- These older parallel offer RPCs are not part of the canonical Dealer workflow and must not remain callable.
revoke all on function public.dealer_my_service_offers() from public,anon,authenticated;
revoke all on function public.dealer_respond_service_offer(uuid,text,text) from public,anon,authenticated;

do $$
begin
 if has_function_privilege('authenticated','public.dealer_my_service_offers()','execute') then
  raise exception 'LEGACY DEALER SERVICE OFFERS RPC STILL AUTHENTICATED-CALLABLE';
 end if;
 if has_function_privilege('authenticated','public.dealer_respond_service_offer(uuid,text,text)','execute') then
  raise exception 'LEGACY DEALER SERVICE OFFER RESPONSE RPC STILL AUTHENTICATED-CALLABLE';
 end if;
end $$;
