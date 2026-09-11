-- TORVO V2 secure administration and notification actions.
create or replace function update_app_user(p_user uuid,p_role text,p_active boolean,p_reason text) returns void language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;t app_users%rowtype;owners integer;begin
select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'Not authorized';end if;
select * into t from app_users where id=p_user for update;if not found then raise exception 'User not found';end if;
if p_role not in('owner','admin','salesman','accountant','store_keeper','dealer') then raise exception 'Invalid role';end if;if nullif(trim(p_reason),'') is null then raise exception 'Reason required';end if;
if a.role='admin' and(t.role='owner' or p_role='owner') then raise exception 'Only Owner can manage Owner role';end if;
if t.id=a.id and p_active=false then raise exception 'Cannot deactivate your own active account';end if;
-- Never allow the system to lose its final active Owner through demotion or deactivation.
if t.role='owner' and t.active=true and (p_role<>'owner' or p_active=false) then select count(*) into owners from app_users where role='owner' and active=true;if owners<=1 then raise exception 'Cannot remove or deactivate the last active Owner';end if;end if;
update app_users set role=p_role,active=p_active where id=p_user;
insert into audit_log(actor_id,action,entity_type,entity_id,details) values(a.id,'APP_USER_UPDATED','app_user',p_user::text,jsonb_build_object('old_role',t.role,'new_role',p_role,'old_active',t.active,'new_active',p_active,'reason',trim(p_reason)));
end;$$;
revoke all on function update_app_user(uuid,text,boolean,text) from public,anon;grant execute on function update_app_user(uuid,text,boolean,text) to authenticated;
create or replace function mark_notification_read(p_notification uuid) returns void language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found then raise exception 'Active user required';end if;update notifications set read_at=coalesce(read_at,now()) where id=p_notification and user_id=a.id;if not found then raise exception 'Notification not found';end if;end;$$;
revoke all on function mark_notification_read(uuid) from public,anon;grant execute on function mark_notification_read(uuid) to authenticated;
