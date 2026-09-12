-- TORVO V2 PUBLIC CUSTOMER REFERRAL CREATION
-- NO PUBLIC RATE / CHECKOUT. SERVER RESOLVES CUSTOMER, ACTIVE BENEFIT AND REFERRAL CODE.
create or replace function public_create_customer_referral(p_full_name text,p_mobile text,p_pin_code text,p_product_id uuid,p_dealer_id uuid default null,p_marketing_opt_in boolean default false)
returns table(referral_id uuid,referral_code text,expires_at timestamptz,benefit_type text,benefit_value numeric,benefit_text text,dealer_id uuid)
language plpgsql security definer set search_path=public as $$
declare v_mobile text;v_customer uuid;v_campaign referral_benefit_campaigns%rowtype;v_ref uuid;v_code text;v_exp timestamptz:=now()+interval '7 days';v_item catalog_items%rowtype;
begin
 if nullif(btrim(p_full_name),'') is null then raise exception 'NAME REQUIRED';end if;v_mobile:=regexp_replace(coalesce(p_mobile,''),'\D','','g');if length(v_mobile)>10 then v_mobile:=right(v_mobile,10);end if;if length(v_mobile)<>10 then raise exception 'VALID 10 DIGIT MOBILE REQUIRED';end if;if btrim(coalesce(p_pin_code,''))!~'^[0-9]{6}$' then raise exception 'VALID 6 DIGIT PIN CODE REQUIRED';end if;
 select * into v_item from catalog_items where id=p_product_id and active=true;if v_item.id is null then raise exception 'ACTIVE PRODUCT REQUIRED';end if;
 if p_dealer_id is not null then perform 1 from dealers d where d.id=p_dealer_id and d.status='approved' and d.customer_referral_enabled=true and d.referral_profile_verified_at is not null;if not found then raise exception 'APPROVED REFERRAL DEALER REQUIRED';end if;
 insert into customer_contacts(full_name,mobile,whatsapp,pin_code,marketing_opt_in,marketing_opt_in_at,marketing_opt_in_source) values(upper(btrim(p_full_name)),v_mobile,v_mobile,btrim(p_pin_code),coalesce(p_marketing_opt_in,false),case when p_marketing_opt_in then now() end,case when p_marketing_opt_in then 'customer_referral' end) on conflict(mobile) do update set full_name=excluded.full_name,whatsapp=excluded.whatsapp,pin_code=excluded.pin_code,marketing_opt_in=case when customer_contacts.marketing_opt_out_at is not null then false else customer_contacts.marketing_opt_in or excluded.marketing_opt_in end,marketing_opt_in_at=case when customer_contacts.marketing_opt_out_at is null and excluded.marketing_opt_in then coalesce(customer_contacts.marketing_opt_in_at,now()) else customer_contacts.marketing_opt_in_at end,updated_at=now() returning id into v_customer;
 select * into v_campaign from referral_benefit_campaigns b where b.active=true and (b.starts_at is null or b.starts_at<=now()) and (b.ends_at is null or b.ends_at>now()) and (b.scope='all' or (b.scope='item_type' and b.item_type=v_item.item_type) or (b.scope='product' and b.product_id=v_item.id)) order by case b.scope when 'product' then 1 when 'item_type' then 2 else 3 end,b.created_at desc limit 1;
 for i in 1..10 loop v_code:='TV-'||upper(substr(encode(gen_random_bytes(5),'hex'),1,7));exit when not exists(select 1 from customer_dealer_referrals where customer_dealer_referrals.referral_code=v_code);end loop;if exists(select 1 from customer_dealer_referrals where customer_dealer_referrals.referral_code=v_code) then raise exception 'REFERRAL CODE GENERATION FAILED';end if;
 insert into customer_dealer_referrals(referral_code,customer_id,product_id,dealer_id,benefit_campaign_id,customer_pin_code,status,expires_at,dealer_selected_at) values(v_code,v_customer,v_item.id,p_dealer_id,v_campaign.id,btrim(p_pin_code),case when p_dealer_id is null then 'created' else 'dealer_selected' end,v_exp,case when p_dealer_id is not null then now() end) returning id into v_ref;
 return query select v_ref,v_code,v_exp,v_campaign.benefit_type,v_campaign.benefit_value,v_campaign.benefit_text,p_dealer_id;
end$$;
revoke all on function public_create_customer_referral(text,text,text,uuid,uuid,boolean) from public;grant execute on function public_create_customer_referral(text,text,text,uuid,uuid,boolean) to anon,authenticated;

create or replace function public_customer_catalog(p_search text default null,p_limit integer default 60)
returns table(id uuid,item_code text,name text,item_type text,brand text,category text,model text,image_url text)
language sql security definer set search_path=public as $$select c.id,c.item_code,c.name,c.item_type,c.brand,c.category,c.model,c.image_url from catalog_items c where c.active=true and (nullif(btrim(p_search),'') is null or concat_ws(' ',c.item_code,c.name,c.brand,c.category,c.model) ilike '%'||btrim(p_search)||'%') order by c.name limit greatest(1,least(coalesce(p_limit,60),100))$$;
revoke all on function public_customer_catalog(text,integer) from public;grant execute on function public_customer_catalog(text,integer) to anon,authenticated;

-- ADVANCED CUSTOMER DISCOVERY: NO RATE OR PRIVATE INVENTORY VALUE IS RETURNED.
create or replace function public_customer_catalog_filtered(p_search text default null,p_item_type text default null,p_brand text default null,p_category text default null,p_model text default null,p_sort text default 'RELEVANT',p_limit integer default 60)
returns table(id uuid,item_code text,name text,item_type text,brand text,category text,model text,image_url text,available boolean)
language sql security definer set search_path=public as $$
 select c.id,c.item_code,c.name,c.item_type,c.brand,c.category,c.model,c.image_url,coalesce(i.current_qty,0)>0
 from catalog_items c left join inventory i on i.item_id=c.id
 where c.active=true
 and (nullif(btrim(p_search),'') is null or concat_ws(' ',c.item_code,c.name,c.brand,c.category,c.model) ilike '%'||btrim(p_search)||'%')
 and (nullif(btrim(p_item_type),'') is null or c.item_type=lower(btrim(p_item_type)))
 and (nullif(btrim(p_brand),'') is null or upper(c.brand)=upper(btrim(p_brand)))
 and (nullif(btrim(p_category),'') is null or upper(c.category)=upper(btrim(p_category)))
 and (nullif(btrim(p_model),'') is null or upper(c.model)=upper(btrim(p_model)))
 order by case when upper(p_sort)='AVAILABLE' and coalesce(i.current_qty,0)>0 then 0 else 1 end,
 case when upper(p_sort)='NEWEST' then c.created_at end desc nulls last,c.name
 limit greatest(1,least(coalesce(p_limit,60),100));
$$;
revoke all on function public_customer_catalog_filtered(text,text,text,text,text,text,integer) from public;grant execute on function public_customer_catalog_filtered(text,text,text,text,text,text,integer) to anon,authenticated;

create or replace function public_customer_filter_options(p_item_type text default null)
returns table(filter_name text,filter_value text)
language sql security definer set search_path=public as $$
 select 'BRAND',brand from(select distinct upper(btrim(brand)) brand from catalog_items where active=true and nullif(btrim(brand),'') is not null and (nullif(btrim(p_item_type),'') is null or item_type=lower(btrim(p_item_type))))x
 union all select 'CATEGORY',category from(select distinct upper(btrim(category)) category from catalog_items where active=true and nullif(btrim(category),'') is not null and (nullif(btrim(p_item_type),'') is null or item_type=lower(btrim(p_item_type))))x
 union all select 'MODEL',model from(select distinct upper(btrim(model)) model from catalog_items where active=true and nullif(btrim(model),'') is not null and (nullif(btrim(p_item_type),'') is null or item_type=lower(btrim(p_item_type))))x
 order by 1,2;
$$;
revoke all on function public_customer_filter_options(text) from public;grant execute on function public_customer_filter_options(text) to anon,authenticated;
