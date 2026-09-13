-- TORVO V2 UNIFIED MEDIA STORAGE
-- USE THE EXISTING SUPABASE PLATFORM: NO SEPARATE IMAGE HOSTING PROVIDER REQUIRED.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('torvo-product-media','torvo-product-media',true,8388608,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

-- ONLY ACTIVE OWNER/ADMIN MAY WRITE PRODUCT/DRAFT MEDIA. PUBLIC MAY READ PRODUCT MEDIA.
drop policy if exists torvo_product_media_admin_insert on storage.objects;
create policy torvo_product_media_admin_insert on storage.objects for insert to authenticated with check(bucket_id='torvo-product-media' and exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and u.active=true and u.role in('owner','admin')));
drop policy if exists torvo_product_media_admin_update on storage.objects;
create policy torvo_product_media_admin_update on storage.objects for update to authenticated using(bucket_id='torvo-product-media' and exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and u.active=true and u.role in('owner','admin'))) with check(bucket_id='torvo-product-media');
drop policy if exists torvo_product_media_admin_delete on storage.objects;
create policy torvo_product_media_admin_delete on storage.objects for delete to authenticated using(bucket_id='torvo-product-media' and exists(select 1 from public.app_users u where u.auth_user_id=auth.uid() and u.active=true and u.role in('owner','admin')));
