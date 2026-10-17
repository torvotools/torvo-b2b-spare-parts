# TORVO V2 — Owner-controlled delegated permissions (implementation contract)

Status: REQUIREMENT LOCKED; NOT YET DEPLOYED. Applies to the existing single V2 backend only.

## Authority
- Owner OR@000 has every available module/action, including role and permission administration.
- No other role, including admin, can grant permissions, alter its own grants, revoke the owner, change owner identity, or grant another person owner status.
- Admin AD@001 has only grants assigned by Owner. No hard-coded blanket admin privileges should bypass server-side checks.
- Owner may grant selected administrative capabilities to an existing salesman/store keeper/accountant without changing or overwriting their underlying staff ID, role, attendance, or history.
- Deny by default. Permissions are scoped to explicit module + action (view/create/edit/delete/approve/export/manage). Sensitive actions must be separately granted.
- Optional start/end validity, immediate revocation, reason, actor, timestamps, and immutable audit records.
- Any change must take effect on the server immediately (not rely on cached client roles or UI hiding).
- No grant may override existing security constraints: desktop-only accountant/owner/admin login, mobile-only operational staff login, dealer boundaries, approved Marg Bill workflow, production safeguards.
- Delegated admin access from a mobile staff identity does not automatically unlock desktop login; privileged desktop access requires a separate explicitly approved authentication policy, verified before implementation.

## Required staged implementation
1. Audit every current owner/admin authorization in RPCs, Edge Functions, RLS policies and UI; catalog permission gates and sensitive operations.
2. Add a staging-only migration with normalized grants and revocation/audit schema. Secure RLS; authenticated staff cannot directly mutate grants.
3. Create owner-only SECURITY DEFINER grant/revoke/list RPCs with verified actor, role, target, action, time range and audit logging.
4. Replace each relevant backend authorization check with a centralized effective-permission check. Owner override; other users grant-only; deny on failure.
5. Build Owner Permission Management UI, per-employee grants and action toggles. UI is presentation, not authorization.
6. Add tests for cross-role escalation, self-grants, revoked sessions, expired grants, impersonation, unauthorized export and owner protection.
7. Verify STAGING end-to-end, then request explicit Owner approval before any production rollout.

## Salesman management
- Up to ten reserved IDs SM@001–SM@010, each linked to one real active staff account.
- Owner/Admin can register staff details only with a specifically granted staff-management permission; creating a staff account must not itself grant admin capabilities.
- Never auto-create placeholder salesman accounts, bypass email OTP or approve unverified staff.
