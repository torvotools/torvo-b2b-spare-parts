-- TORVO V2 RETIRED SECURE DESKTOP CHALLENGE CLEANUP
-- Canonical Staff login is USER ID + master-email OTP + staff_auth_sessions.
-- Manual/parallel secure-desktop challenge verification is retired.
-- Keep this file in install order only as an idempotent cleanup for older environments.

revoke all on function public.secure_desktop_create_challenge(uuid,text,integer) from public,anon,authenticated;
revoke all on function public.secure_desktop_is_verified(text) from public,anon,authenticated;
revoke all on function public.secure_desktop_revoke(text) from public,anon,authenticated;
revoke all on function public.secure_desktop_verify_code(uuid,text,text) from public,anon,authenticated;

drop function if exists public.secure_desktop_is_verified(text);
drop function if exists public.secure_desktop_revoke(text);
drop function if exists public.secure_desktop_verify_code(uuid,text,text);
drop function if exists public.secure_desktop_create_challenge(uuid,text,integer);

drop table if exists public.secure_desktop_verification_audit;
drop table if exists public.secure_desktop_verified_sessions;
drop table if exists public.secure_desktop_verification_challenges;
