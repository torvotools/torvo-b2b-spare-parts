-- TORVO V2: PRIVILEGED EXACT-CODE AND CONSERVATIVE LIKELY-DUPLICATE SEARCH
-- Apply on STAGING first; never expose catalog/draft internals to anon/dealer.
create or replace function admin_product_duplicate_matches(
 p_item_code text default null,p_name text default null,p_brand text default null,
 p_model text default null,p_exclude_draft_id uuid default null,p_limit integer default 20
) returns table(source text,item_id uuid,item_code text,name text,brand text,model text,image_url text,match_reason text)
language plpgsql security definer set search_path=public as $$
declare u app_users%rowtype;v_code text;v_name text;v_brand text;v_model text;begin
 select * into u from app_users where auth_user_id=auth.uid() and active=true;
 if u.id is null or u.role not in('owner','admin') then raise exception 'ADMIN ACCESS REQUIRED';end if;
 v_code:=upper(nullif(btrim(p_item_code),''));
 v_name:=upper(nullif(btrim(p_name),''));
 v_brand:=upper(nullif(btrim(p_brand),''));
 v_model:=upper(nullif(btrim(p_model),''));
 if v_code is null and v_name is null then return;end if;
 return query
 with candidates as (
 select 'PRODUCT MASTER'::text as source,c.id as item_id,c.item_code,c.name,c.brand,c.model,c.image_url,
 case when v_code is not null and upper(btrim(c.item_code))=v_code then 'EXACT CODE' else 'POSSIBLE DUPLICATE' end::text as match_reason
 from catalog_items c
 where (v_code is not null and upper(btrim(c.item_code))=v_code)
 or (v_name is not null and v_brand is not null and v_model is not null and upper(btrim(c.name))=v_name and upper(btrim(coalesce(c.brand,'')))=v_brand and upper(btrim(coalesce(c.model,'')))=v_model)
 union all
 select 'DRAFT LIBRARY'::text,d.id,d.item_code,d.name,d.brand,d.model,d.image_url,
 case when v_code is not null and upper(btrim(d.item_code))=v_code then 'EXACT CODE' else 'POSSIBLE DUPLICATE' end::text
 from product_draft_library d
 where d.status='draft' and d.id is distinct from p_exclude_draft_id
 and ((v_code is not null and upper(btrim(d.item_code))=v_code)
 or (v_name is not null and v_brand is not null and v_model is not null and upper(btrim(d.name))=v_name and upper(btrim(coalesce(d.brand,'')))=v_brand and upper(btrim(coalesce(d.model,'')))=v_model))
 )
 select x.source,x.item_id,x.item_code,x.name,x.brand,x.model,x.image_url,x.match_reason
 from candidates x order by case when x.match_reason='EXACT CODE' then 0 else 1 end,x.source,x.item_code
 limit greatest(1,least(coalesce(p_limit,20),100));
end$$;
revoke all on function admin_product_duplicate_matches(text,text,text,text,uuid,integer) from public;
grant execute on function admin_product_duplicate_matches(text,text,text,text,uuid,integer) to authenticated;
