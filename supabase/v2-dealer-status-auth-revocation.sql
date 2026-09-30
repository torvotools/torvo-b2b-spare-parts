-- TORVO V2 DEALER STATUS DOWNGRADE AUTH REVOCATION
-- Any Owner/Admin status change away from APPROVED must invalidate current Dealer auth state.
create or replace function set_dealer_request_status(p_dealer uuid,p_status text,p_reason text)
returns void language plpgsql security definer set search_path=public as $$
declare a app_users%rowtype;old_status text;
begin
 select * into a from app_users where auth_user_id=auth.uid() and active=true;
 if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
 if p_status not in('pending','hold','rejected','inactive','suspended') or nullif(trim(p_reason),'') is null then raise exception 'Valid status and reason required';end if;
 select status into old_status from dealers where id=p_dealer for update;
 if not found then raise exception 'Dealer not found';end if;
 update dealers set status=p_status where id=p_dealer;
 update app_users set active=false where dealer_id=p_dealer and lower(coalesce(role,''))='dealer' and active=true;
 update dealer_device_sessions set revoked_at=coalesce(revoked_at,now()),revoked_reason=coalesce(revoked_reason,'DEALER_STATUS_CHANGED') where dealer_id=p_dealer and revoked_at is null;
 update dealer_email_otp_challenges set revoked_at=coalesce(revoked_at,now()) where dealer_id=p_dealer and used_at is null and revoked_at is null;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'DEALER_STATUS_CHANGED','dealer',p_dealer::text,jsonb_build_object('old_status',old_status,'new_status',p_status,'reason',trim(p_reason),'current_auth_revoked',true));
end$$;
revoke all on function set_dealer_request_status(uuid,text,text) from public,anon;
grant execute on function set_dealer_request_status(uuid,text,text) to authenticated;
