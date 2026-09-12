-- TORVO V2 MAKER-CHECKER APPROVAL STAGING CHECKLIST
-- Verification checklist only. Real staging sessions required before runtime-verified claims.

select to_regclass('public.approval_permissions'),to_regclass('public.approval_requests'),to_regclass('public.approval_history');

select p.proname,p.prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in('set_transaction_approval_permission','submit_approval_request','decide_approval_request','get_pending_approval_queue','get_my_approval_work') order by p.proname;

select table_name,privilege_type,grantee from information_schema.role_table_grants
where table_schema='public' and table_name in('approval_permissions','approval_requests','approval_history') and grantee in('anon','authenticated') and privilege_type in('INSERT','UPDATE','DELETE');
-- Expected: zero rows.

-- OWNER permission tests:
-- 1) Owner grants CAN APPROVE TRANSACTIONS to Accountant A only. Accountant B/C cannot decide.
-- 2) Owner can independently grant Accountant A/B/C or any combination.
-- 3) Revoking permission immediately prevents future decisions.
-- 4) Only Owner can change approval permission.

-- MAKER/CHECKER tests:
-- 5) Accountant creates request -> PENDING APPROVAL appears in queue.
-- 6) Authorized Accountant/Admin can APPROVE/REJECT.
-- 7) Unauthorized Accountant cannot decide.
-- 8) Maker cannot approve own request by default.
-- 9) Owner explicitly grants CAN APPROVE OWN ENTRY -> that trusted checker can decide own request.
-- 10) Owner can always decide.
-- 11) Already decided request cannot be decided again.
-- 12) Duplicate active same module/entity/action request returns/keeps one pending request.
-- 13) Maker sees APPROVED/REJECTED status, checker identity/note and timestamps in MY APPROVAL WORK.
-- 14) Approval history + audit_log retain SUBMITTED and APPROVED/REJECTED actor/time evidence.

-- MODULE INTEGRATION RELEASE GATE:
-- The central engine alone does NOT make a transaction approval-controlled.
-- For PAYMENT, PURCHASE, PAYMENT OUT, SALES FINANCIAL CORRECTION and REVERSAL,
-- verify the module's final-effect RPC explicitly requires an APPROVED request before releasing its final effect.
-- Never claim a module is maker-checker protected until that gate is wired and staging-tested.
