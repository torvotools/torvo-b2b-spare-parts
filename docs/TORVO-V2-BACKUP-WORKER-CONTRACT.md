# TORVO V2 BACKUP WORKER CONTRACT

## PURPOSE

This is the trust boundary between Backup Control Center metadata and the server-side process that creates/verifies real backup artifacts. Browser code must never receive database/service-role/provider secrets and must never be authoritative for VERIFIED status.

## REQUEST INPUT

A queued backup request supplies only non-secret identifiers/configuration needed to select the requested backup type and correlate the run. The worker resolves all privileged credentials from its protected runtime secret store.

Supported control intent includes DATABASE BACKUP, FULL RESTORE POINT and CONFIGURATION EXPORT. A request remains REQUESTED/QUEUED until trusted processing begins.

## TRUSTED WORKER STEPS

1. Claim one eligible queued run atomically so two workers cannot process the same run concurrently.
2. Record processing start/audit metadata.
3. Create the requested database/configuration artifact using server-side credentials only.
4. Exclude passwords, PIN/OTP secrets, service-role keys, provider credentials and other secrets from portable artifacts.
5. Encrypt portable backup content before durable storage/export.
6. Calculate integrity checksum after the final artifact is produced.
7. For FULL RESTORE POINT, create a restore manifest containing at minimum:
   - backup run ID and backup type;
   - created/verified timestamps;
   - code repository + `torvo-v2-build` branch + exact commit SHA;
   - database/schema migration/version marker;
   - artifact format/version;
   - checksum algorithm + checksum;
   - restore prerequisites/instructions version;
   - non-secret artifact object/location identifier.
8. Persist worker completion through the protected server-side completion contract.
9. Mark VERIFIED only after artifact creation and integrity verification both succeed.
10. On any failure, record FAILED + sanitized error/audit metadata. Never expose credentials in error text.

## IDEMPOTENCY / CONCURRENCY

- Run ID is the idempotency key.
- Claim/complete/fail transitions must be atomic and auditable.
- Replaying completion for an already VERIFIED run must not create a second logical artifact or silently replace checksum/manifest evidence.
- A failed/retried worker must not cause duplicate backup history that masquerades as separate successful backups.

## SECURE DOWNLOAD / SHARE

The browser may request an authorized export, but a trusted server path must issue a short-lived signed download or perform provider delivery. Long-lived storage credentials are never returned to the client. EMAIL/WHATSAPP UI may report SENT only after the provider returns successful delivery/acceptance evidence defined by that integration; opening a prepared link is not proof of sending.

## VERIFIED BACKUP AGE

Dashboard health is calculated from the latest VERIFIED backup timestamp only:

- under 24 hours: HEALTHY;
- 24 hours or more: WARNING;
- 48 hours or more: CRITICAL.

REQUESTED, RUNNING or FAILED runs never reset verified-backup age.

## RESTORE DRILL

A backup is not production-trusted until an encrypted artifact has been restored into a clean staging target, checksum/manifest validation succeeds, and TORVO's critical role/privacy/order/payment/stock tests pass against the restored environment.
