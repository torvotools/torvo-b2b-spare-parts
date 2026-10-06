-- TORVO V2 FINAL DEALER PROCUREMENT DEVICE BOUNDARY
-- Install after v2-business-rpcs.sql and dealer auth assertion.

drop function if exists dealer_item_rate(uuid,numeric);
drop function if exists submit_purchase_order(jsonb);

create or replace function dealer_item_rate(p_item uuid,p_qty numeric,p_device_id text,p_session_token text) returns table(item_id uuid,item_code text,item_name text,qty numeric,rate numeric,amount numeric) language plpgsql security definer set search_path=public as $$declare did uuid;rg text;r numeric;begin did:=dealer_assert_my_device_session(p_device_id,p_session_token);if p_qty is null or p_qty<=0 or p_qty<>trunc(p_qty) or p_qty>9999 then raise exception 'QUANTITY MUST BE INTEGER 1 TO 9999';end if;select d.rate_group into rg from dealers d where d.id=did and d.status='approved';if rg is null then raise exception 'APPROVED DEALER RATE GROUP REQUIRED';end if;select ir.selling_rate into r from item_rates ir where ir.item_id=p_item and ir.rate_group=rg and ir.min_qty<=p_qty order by ir.min_qty desc limit 1;if r is null then raise exception 'RATE NOT AVAILABLE FOR THIS QUANTITY';end if;return query select c.id,c.item_code,c.name,p_qty,r,round(p_qty*r,2) from catalog_items c where c.id=p_item and c.active=true;if not found then raise exception 'ITEM NOT AVAILABLE';end if;end$$;

create table if not exists dealer_purchase_order_requests(
 dealer_id uuid not null references dealers(id) on delete cascade,
 request_key text not null,
 payload jsonb not null,
 sales_order_id uuid references sales_documents(id) on delete set null,
 created_at timestamptz not null default now(),
 primary key(dealer_id,request_key)
);
alter table dealer_purchase_order_requests enable row level security;
revoke all on dealer_purchase_order_requests from public,anon,authenticated;

drop function if exists submit_purchase_order(jsonb,text,text);
create or replace function submit_purchase_order(p_lines jsonb,p_request_key text,p_device_id text,p_session_token text) returns uuid language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;did uuid;rg text;oid uuid;existing dealer_purchase_order_requests%rowtype;ln jsonb;iid uuid;q numeric;r numeric;sub numeric:=0;k text:=trim(coalesce(p_request_key,''));begin did:=dealer_assert_my_device_session(p_device_id,p_session_token);if length(k)<16 or length(k)>128 then raise exception 'VALID PURCHASE ORDER REQUEST KEY REQUIRED';end if;if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'ORDER LINES REQUIRED';end if;if exists(select 1 from(select x->>'item_id' item_id,count(*) c from jsonb_array_elements(p_lines)x group by x->>'item_id')s where s.item_id is null or s.c>1)then raise exception 'DUPLICATE OR MISSING ITEM IN PURCHASE ORDER';end if;
insert into dealer_purchase_order_requests(dealer_id,request_key,payload)values(did,k,p_lines) on conflict(dealer_id,request_key) do nothing;
select * into existing from dealer_purchase_order_requests where dealer_id=did and request_key=k for update;
if existing.payload<>p_lines then raise exception 'PURCHASE ORDER REQUEST KEY PAYLOAD MISMATCH';end if;
if existing.sales_order_id is not null then return existing.sales_order_id;end if;
select * into a from app_users where auth_user_id=auth.uid() and active=true and role='dealer';if not found then raise exception 'ACTIVE DEALER APP USER REQUIRED';end if;select d.rate_group into rg from dealers d where d.id=did and d.status='approved';if rg is null then raise exception 'APPROVED DEALER REQUIRED';end if;insert into sales_documents(dealer_id,doc_type,status,subtotal,final_payable,created_by,revision_no,dealer_modification_limit,dealer_modifications_used)values(did,'sales_order','submitted',0,0,a.id,1,2,0)returning id into oid;for ln in select * from jsonb_array_elements(p_lines)loop begin iid:=(ln->>'item_id')::uuid;q:=(ln->>'qty')::numeric;exception when others then raise exception 'INVALID ORDER LINE';end;if q is null or q<=0 or q<>trunc(q) or q>9999 then raise exception 'QUANTITY MUST BE INTEGER 1 TO 9999';end if;perform 1 from catalog_items where id=iid and active=true;if not found then raise exception 'ITEM UNAVAILABLE';end if;select selling_rate into r from item_rates where item_id=iid and rate_group=rg and min_qty<=q order by min_qty desc limit 1;if r is null then raise exception 'RATE UNAVAILABLE FOR AN ITEM';end if;insert into sales_document_lines(document_id,item_id,qty,rate,amount)values(oid,iid,q,r,round(q*r,2));sub:=sub+round(q*r,2);end loop;update sales_documents set subtotal=sub,final_payable=sub,root_order_id=oid where id=oid;update dealer_purchase_order_requests set sales_order_id=oid where dealer_id=did and request_key=k;insert into sales_order_revisions(sales_order_id,revision_no,changed_by,actor_role,change_reason,after_data)values(oid,1,a.id,'dealer','PURCHASE ORDER SUBMITTED',jsonb_build_object('subtotal',sub,'lines',p_lines,'request_key',k));insert into audit_log(actor_id,action,entity_type,entity_id,details)values(a.id,'PURCHASE_ORDER_SUBMITTED','sales_order',oid::text,jsonb_build_object('dealer_id',did,'subtotal',sub,'request_key',k));return oid;end$$;

revoke all on function dealer_item_rate(uuid,numeric,text,text),submit_purchase_order(jsonb,text,text,text) from public,anon;
grant execute on function dealer_item_rate(uuid,numeric,text,text),submit_purchase_order(jsonb,text,text,text) to authenticated;
