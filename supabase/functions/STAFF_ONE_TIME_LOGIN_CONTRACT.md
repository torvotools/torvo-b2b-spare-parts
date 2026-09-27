# TORVO V2 STAFF EMAIL OTP CONTRACT

Canonical normal staff login is `staff-email-otp`.

1. OWNER, ADMIN, ACCOUNTANT, SALESMAN and STORE_KEEPER use Staff User ID plus a server-generated 6-digit OTP.
2. Every staff OTP is delivered only to the single Owner/Admin-controlled Master OTP Email configured server-side.
3. The OTP email identifies role, Staff User ID, employee name, login type/context and device type.
4. OTP lifetime is 10 minutes, single-use, resend throttled, maximum five failed attempts; plaintext OTP is never stored.
5. The exact device/installation must already be authorized. OWNER/ADMIN/ACCOUNTANT require `desktop`; SALESMAN/STORE_KEEPER require `mobile_app`.
6. Native app reinstall creates a new installation identity and therefore requires new device approval plus a new OTP.
7. Verified staff sessions remain device-bound; browser/app runtime role boundaries still apply after authentication.
8. OTP verification and trusted session creation RPCs are service-role only. Never expose service-role credentials to browser/app.
9. OWNER is not a bypass path: OR@000 follows the same master-email OTP and approved-desktop-device boundary.
10. The deployed legacy `staff-one-time-login` endpoint remains retired/fail-closed and must return no login session.
