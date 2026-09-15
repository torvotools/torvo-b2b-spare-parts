-- TORVO V2 CUSTOMER LEAD NOTIFICATIONS
-- PRIVACY RULE: DEALER ALERT CONTAINS REQUIREMENT/AREA ONLY. CUSTOMER CONTACT IS NEVER COPIED INTO NOTIFICATION DATA.
create or replace function admin_notify_customer_demand_dealer(p_lead_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;l customer_demand_dealer_leads%rowtype;d customer_product_demands%rowtype;dealer_user uuid;cid uuid;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 select * into l from customer_demand_dealer_leads where id=p_lead_id and status='sent' for update;
 if l.id is null then raise exception 'OPEN ASSIGNED CUSTOMER LEAD REQUIRED';end if;
 select * into d from customer_product_demands where id=l.demand_id and status not in('closed','cancelled') for update;
 if d.id is null then raise exception 'ACTIVE CUSTOMER REQUIREMENT REQUIRED';end if;
 select a.id into dealer_user from app_users a join dealers x on x.id=l.dealer_id where a.dealer_id=l.dealer_id and a.active=true and a.role='dealer' and x.status='approved' order by a.created_at desc limit 1;
 if dealer_user is null then raise exception 'ACTIVE APPROVED DEALER APP USER REQUIRED';end if;
 -- Retry-safe: reuse the existing direct campaign and recover any missing active-device push rows.
 select c.id into cid from app_notification_campaigns c join app_notification_inbox i on i.campaign_id=c.id
 where c.notification_type='customer_lead' and c.action_key='CUSTOMER_LEAD' and c.action_value=l.id::text and c.status='published' and i.user_id=dealer_user
 order by c.created_at desc limit 1;
 if cid is not null then
  insert into app_push_outbox(inbox_id,push_device_id)
  select i.id,p.id from app_notification_inbox i join app_push_devices p on p.user_id=i.user_id and p.active=true
  where i.campaign_id=cid and i.user_id=dealer_user on conflict do nothing;
  return cid;
 end if;
 insert into app_notification_campaigns(title,body,target_roles,notification_type,action_key,action_value,status,created_by,published_at)
 values('NEW CUSTOMER REQUIREMENT',left(coalesce(d.search_text,'PRODUCT REQUIREMENT')||' · AREA '||coalesce(d.pin_code,'NOT PROVIDED')||' · OPEN LEAD',500),array['dealer'],'customer_lead','CUSTOMER_LEAD',l.id::text,'published',u.id,now()) returning id into cid;
 insert into app_notification_inbox(campaign_id,user_id) values(cid,dealer_user);
 insert into app_push_outbox(inbox_id,push_device_id) select i.id,p.id from app_notification_inbox i join app_push_devices p on p.user_id=i.user_id and p.active=true where i.campaign_id=cid and i.user_id=dealer_user on conflict do nothing;
 insert into audit_log(actor_id,action,entity_type,entity_id,details) values(u.id,'CUSTOMER_LEAD_DEALER_NOTIFIED','CUSTOMER_DEMAND_DEALER_LEAD',l.id::text,jsonb_build_object('dealer_id',l.dealer_id,'demand_id',l.demand_id));
 return cid;
end$$;
revoke all on function admin_notify_customer_demand_dealer(uuid) from public,anon;grant execute on function admin_notify_customer_demand_dealer(uuid) to authenticated;
