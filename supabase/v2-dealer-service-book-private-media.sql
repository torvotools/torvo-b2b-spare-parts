-- TORVO V2 DEALER SERVICE BOOK PRIVATE MACHINE MEDIA
-- Private repair-customer operational media. Never public and never marketing data.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('torvo-service-book-media','torvo-service-book-media',false,8388608,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

-- No direct anon/authenticated Storage access. A trusted device-bound worker will own upload/read.
drop policy if exists torvo_service_book_media_insert on storage.objects;
drop policy if exists torvo_service_book_media_select on storage.objects;
drop policy if exists torvo_service_book_media_update on storage.objects;
drop policy if exists torvo_service_book_media_delete on storage.objects;

create or replace function dealer_service_job_media_authorize(
 p_device_id text,p_session_token text,p_job_id uuid default null
) returns uuid language plpgsql security definer set search_path=public as $$
declare did uuid;
begin
 if auth.uid() is null then raise exception 'AUTHENTICATED DEALER REQUIRED';end if;
 did:=dealer_assert_my_device_session(p_device_id,p_session_token);
 if p_job_id is not null then
   perform 1 from dealer_service_jobs where id=p_job_id and dealer_id=did;
   if not found then raise exception 'SERVICE JOB NOT FOUND';end if;
 end if;
 return did;
end$$;
revoke all on function dealer_service_job_media_authorize(text,text,uuid) from public,anon;
grant execute on function dealer_service_job_media_authorize(text,text,uuid) to authenticated;
