-- TORVO V2 TARGET/REWARD ADMIN READ MODEL
-- OWNER/ADMIN ONLY. No arbitrary point-credit API is exposed here.
create or replace function admin_dealer_target_reward_data() returns jsonb language plpgsql security definer set search_path=public as $$
declare a uuid:=reward_admin_user();y int:=reward_scheme_year();begin
 return jsonb_build_object(
  'scheme_year',y,
  'target_types',coalesce((select jsonb_agg(to_jsonb(t) order by t.name) from dealer_target_types t),'[]'::jsonb),
  'target_slabs',coalesce((select jsonb_agg(to_jsonb(s) order by s.target_value) from dealer_target_slabs s),'[]'::jsonb),
  'assignments',coalesce((select jsonb_agg(to_jsonb(x) order by x.scheme_year desc) from dealer_target_assignments x),'[]'::jsonb),
  'reward_options',coalesce((select jsonb_agg(to_jsonb(r) order by r.points_required) from dealer_reward_catalog r),'[]'::jsonb),
  'claims',coalesce((select jsonb_agg(to_jsonb(c) order by c.requested_at desc) from dealer_reward_claims c),'[]'::jsonb),
  'dealers',coalesce((select jsonb_agg(jsonb_build_object('id',d.id,'dealer_code',d.dealer_code,'shop_name',d.shop_name) order by d.shop_name) from dealers d where d.status='approved'),'[]'::jsonb)
 );
end$$;
revoke all on function admin_dealer_target_reward_data() from public,anon;grant execute on function admin_dealer_target_reward_data() to authenticated;
