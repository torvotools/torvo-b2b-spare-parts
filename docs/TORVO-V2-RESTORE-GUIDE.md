# TORVO V2 — START HERE / RESTORE GUIDE

This guide must be included in every verified PROJECT RESTORE PACKAGE.

## Package identity
Record: backup ID, created/verified time, Git branch + exact commit, database/schema version, SHA-256 checksum, included modules and encrypted artifact names. Never include passwords, OTP secrets, service-role keys or provider credentials.

## Recovery order
1. Create a clean recovery/staging environment. Do not overwrite the live system first.
2. Verify every backup artifact checksum before restoring.
3. Restore the exact recorded TORVO code commit/branch.
4. Configure environment secrets separately from the encrypted secret store/provider. Never copy secrets from this package because they are intentionally excluded.
5. Restore the database backup into the clean database.
6. Apply only migrations explicitly listed by the package manifest and in `supabase/V2_INSTALL_ORDER.md`; never run SQL alphabetically.
7. Configure storage/email/WhatsApp/provider settings only after core database and authentication work.
8. Build the exact recorded V2 source and run role/security tests.
9. Test Owner, Admin, Salesman, Accountant, Store Keeper and Dealer access; Dealer isolation; pricing; Purchase; payment; delivery; exactly-once stock movement; private Suitable data; and backup control.
10. Compare restored record counts/checksums and critical business totals with the restore manifest.
11. Only after recovery verification may DNS/live traffic be changed, and only with explicit Owner approval.

## Failure rule
If checksum, database restore, migration, authentication, role isolation, pricing, stock or financial integrity test fails: STOP. Keep the current live system untouched and record the failure. Never silently repair financial/history rows by deleting or inventing data.

## TORVO safety
V27/main remains untouched during V2 development. A restore package is a recovery source, not permission to replace production. Actual restore drills must be tested periodically so a backup is not trusted merely because a file exists.
