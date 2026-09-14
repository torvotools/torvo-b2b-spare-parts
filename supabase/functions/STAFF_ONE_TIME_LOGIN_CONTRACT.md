# STAFF ONE-TIME LOGIN — TRUSTED WORKER CONTRACT

Endpoint: `staff-one-time-login`.

1. Accept only `username`, `password`, `device_id`, `device_type` over HTTPS.
2. Reject malformed username/password/device input before any privileged call.
3. Use server-only credentials to call `staff_verify_one_time_password(username,password,device_id,device_type)`.
4. That database call must verify the Admin-approved device and atomically consume the one-time password.
5. Resolve the returned `app_user_id`; require active role SALESMAN, STORE_KEEPER or ACCOUNTANT.
6. Enforce device type again server-side: SALESMAN/STORE_KEEPER=`mobile_app`; ACCOUNTANT=`desktop`.
7. Establish/resolve the real Supabase Auth identity server-side. Never send a service-role key to browser/app.
8. Call trusted `staff_create_verified_session(auth_user_id,device_id,'admin_one_time_password')` only after identity and role checks pass.
9. Return only safe fields: `ok`, `session_id`, normalized role, employee display name and normal Supabase user session material required by the official client. Never return password/hash/service secrets.
10. On failure return a generic login error; do not reveal whether username, password or employee record exists.
11. Rate-limit repeated failures by username + device + network risk signal. Log security events without plaintext password.
12. Logout/revoke must revoke `staff_auth_sessions`; next login requires a newly Admin-issued one-time password.
13. A replacement device must be Admin-approved first; password knowledge alone never authorizes a new device.
14. OWNER/ADMIN recovery is out of scope for this endpoint and must use the separately verified Owner/Admin recovery channel.
