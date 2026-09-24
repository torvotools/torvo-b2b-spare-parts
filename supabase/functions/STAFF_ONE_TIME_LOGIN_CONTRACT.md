# RETIRED STAFF ONE-TIME LOGIN CONTRACT

The legacy `staff-one-time-login` / Admin-issued password flow is retired and must not be used for normal staff login.

Canonical normal staff login is `staff-email-otp`:
1. ADMIN, ACCOUNTANT, SALESMAN and STORE_KEEPER use Staff User ID plus a server-generated 6-digit OTP.
2. Every staff OTP is delivered only to the single Owner/Admin-controlled Master OTP Email configured server-side.
3. The OTP email identifies role, Staff User ID, employee name, login type/context and device type.
4. OTP lifetime is 10 minutes, single-use, with resend throttling; plaintext OTP is never stored.
5. The exact device/installation must already be Owner/Admin-approved. SALESMAN/STORE_KEEPER require `mobile_app`; ADMIN/ACCOUNTANT require `desktop`.
6. Native app reinstall creates a new installation identity and therefore requires new device approval plus a new OTP.
7. SALESMAN/STORE_KEEPER sessions may last at most 30 days on the same approved installation. Desktop ADMIN/ACCOUNTANT client sessions are browser-session scoped; logout/browser close requires a fresh OTP.
8. OTP verification and trusted session creation RPCs are service-role only. Never expose service-role credentials to browser/app.
9. OWNER is excluded from this normal staff-email OTP flow and retains the separately controlled Owner secure-access path.
10. The deployed legacy `staff-one-time-login` endpoint must remain fail-closed/retired and return no login session.
