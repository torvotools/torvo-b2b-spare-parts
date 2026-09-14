-- TORVO V2 OWNER/ADMIN APP RELEASE CENTER
create table if not exists app_release_artifacts(id uuid primary key default gen_random_uuid(),platform text not null check(platform in('android_apk','android_aab','ios')),version text not null,build_number integer not null check(build_number>0),commit_sha text not null check(commit_sha~'^[0-9a-f]{40}$'),artifact_url text,status text not null default 'building' check(status in('building','verified','failed','published')),verified_at timestamptz,published_at timestamptz,created_at timestamptz not null default now(),unique(platform,version,build_number));
alter table app_release_artifacts add column if not exists package_id text;
alter table app_release_artifacts add column if not exists channel text;
alter table app_release_artifacts add column if not exists production_signed boolean not null default false;
alter table app_release_artifacts add column if not exists artifact_sha256 text;
alter table app_release_artifacts add column if not exists min_supported_build integer;
alter table app_release_artifacts drop constraint if exists app_release_artifacts_package_id_check;
alter table app_release_artifacts add constraint app_release_artifacts_package_id_check check(package_id is null or package_id='com.torvotools.app');
alter table app_release_artifacts drop constraint if exists app_release_artifacts_channel_check;
alter table app_release_artifacts add constraint app_release_artifacts_channel_check check(channel is null or channel in('test-debug','production','play','stable'));
alter table app_release_artifacts drop constraint if exists app_release_artifacts_sha256_check;
alter table app_release_artifacts add constraint app_release_artifacts_sha256_check check(artifact_sha256 is null or artifact_sha256~'^[0-9a-f]{64}$');
alter table app_release_artifacts drop constraint if exists app_release_artifacts_min_build_check;
alter table app_release_artifacts add constraint app_release_artifacts_min_build_check check(min_supported_build is null or min_supported_build>0);
alter table app_release_artifacts enable row level security;revoke all on table app_release_artifacts from public,anon,authenticated;
create or replace function admin_app_release_center() returns setof app_release_artifacts language plpgsql security definer set search_path=public as $$declare a app_users%rowtype;begin select * into a from app_users where auth_user_id=auth.uid() and active=true;if not found or a.role not in('owner','admin') then raise exception 'OWNER/ADMIN REQUIRED';end if;return query select * from app_release_artifacts order by created_at desc limit 50;end;$$;
revoke all on function admin_app_release_center() from public,anon;grant execute on function admin_app_release_center() to authenticated;
create or replace function public_android_app_update() returns table(version text,build_number integer,commit_sha text,artifact_url text,artifact_sha256 text,min_supported_build integer,package_id text,channel text) language sql security definer set search_path=public stable as $$select r.version,r.build_number,r.commit_sha,r.artifact_url,r.artifact_sha256,r.min_supported_build,r.package_id,r.channel from app_release_artifacts r where r.platform='android_apk' and r.status='published' and r.production_signed=true and r.package_id='com.torvotools.app' and r.channel in('production','play','stable') and r.artifact_url~'^https://' and r.artifact_sha256~'^[0-9a-f]{64}$' order by r.build_number desc limit 1$$;
revoke all on function public_android_app_update() from public;grant execute on function public_android_app_update() to anon,authenticated;
-- Release metadata writes are CI/trusted-worker only. Browser roles have no table write grant.
