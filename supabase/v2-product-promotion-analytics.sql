-- TORVO V2 PRODUCT PROMOTION ANALYTICS
-- PRIVACY-SAFE FUNNEL: VIEW -> CLICK -> ENQUIRY -> DEALER_ORDER
create table if not exists product_promotion_events(
  id uuid primary key default gen_random_uuid(),
  promotion_id uuid not null references product_promotions(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  event_type text not null check(event_type in('view','click','enquiry','dealer_order')),
  target text not null check(target in('website','dealer_app')),
  session_key text not null,
  source_ref text,
  dealer_id uuid references dealers(id),
  created_at timestamptz not null default now()
);
create unique index if not exists product_promotion_event_once on product_promotion_events(promotion_id,event_type,target,session_key,coalesce(source_ref,''));
create index if not exists product_promotion_events_created_idx on product_promotion_events(created_at desc);
alter table product_promotion_events enable row level security;
revoke all on product_promotion_events from anon,authenticated;

create or replace function record_product_promotion_event(p_promotion_id uuid,p_event_type text,p_target text,p_session_key text,p_source_ref text default null) returns boolean language plpgsql security definer set search_path=public as $$
declare a product_promotions%rowtype;p products%rowtype;d uuid;
begin
 if p_event_type not in('view','click','enquiry','dealer_order') then raise exception 'INVALID PROMOTION EVENT';end if;
 if p_target not in('website','dealer_app') then raise exception 'INVALID PROMOTION TARGET';end if;
 if nullif(btrim(coalesce(p_session_key,'')),'') is null then raise exception 'SESSION KEY REQUIRED';end if;
 select * into a from product_promotions where id=p_promotion_id and active=true and starts_at<=now() and(ends_at is null or ends_at>=now()) and(target='both' or target=p_target);
 if a.id is null then return false;end if;
 select * into p from products where id=a.product_id and active=true;if p.id is null then return false;end if;
 if p_target='dealer_app' then select dealer_id into d from app_users where auth_user_id=auth.uid() and active=true and role='dealer';end if;
 insert into product_promotion_events(promotion_id,product_id,event_type,target,session_key,source_ref,dealer_id)
 values(a.id,a.product_id,p_event_type,p_target,left(btrim(p_session_key),96),nullif(left(btrim(coalesce(p_source_ref,'')),120),''),d)
 on conflict do nothing;
 return true;
end$$;

create or replace function admin_product_promotion_analytics(p_days int default 30) returns table(promotion_id uuid,title text,target text,views bigint,clicks bigint,enquiries bigint,dealer_orders bigint) language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'OWNER OR ADMIN REQUIRED';end if;
 return query select a.id,a.title,a.target,
 count(e.id) filter(where e.event_type='view'),count(e.id) filter(where e.event_type='click'),count(e.id) filter(where e.event_type='enquiry'),count(e.id) filter(where e.event_type='dealer_order')
 from product_promotions a left join product_promotion_events e on e.promotion_id=a.id and e.created_at>=now()-make_interval(days=>least(greatest(coalesce(p_days,30),1),365))
 group by a.id,a.title,a.target order by max(a.updated_at) desc;
end$$;
revoke all on function record_product_promotion_event(uuid,text,text,text,text),admin_product_promotion_analytics(int) from public;
grant execute on function record_product_promotion_event(uuid,text,text,text,text) to anon,authenticated;
grant execute on function admin_product_promotion_analytics(int) to authenticated;
