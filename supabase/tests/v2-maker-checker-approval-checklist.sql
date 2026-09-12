-- TORVO V2 MAKER-CHECKER APPROVAL STAGING CHECKLIST
-- Verification only. Real staging evidence required before runtime-verified claims.
select to_regclass('public.approval_permissions'),to_regclass('public.approval_requests'),to_regclass('public.approval_history');
select p.proname,p.prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in('set_transaction_approval_permission','submit_approval_request','decide_approval_request','get_pending_approval_queue','get_my_approval_work','submit_payment_for_approval','decide_payment_approval','record_payment','apply_payment_internal','get_approval_permission_users')order by p.proname;
select table_name,privilege_type,grantee from information_schema.role_table_grants where table_schema='public' and table_name in('approval_permissions','approval_requests','approval_history')and grantee in('anon','authenticated')and privilege_type in('INSERT','UPDATE','DELETE');
-- Expected zero direct writes.
select grantee,routine_name,privilege_type from information_schema.role_routine_grants where routine_schema='public' and routine_name='apply_payment_internal' and grantee in('PUBLIC','anon','authenticated');
-- Expected zero rows: internal payment application is never browser executable.
-- OWNER permission: grant any chosen active Admin/Accountant; revoke immediately; non-Owner cannot grant/read permission administration.
-- MAKER/CHECKER: pending queue; authorized approve/reject; unauthorized denied; self approval default denied; explicit Owner self-approval grant works; decided request cannot decide twice; MY WORK retains checker/note/timestamps; audit/history retained.
-- PAYMENT FINAL BOUNDARY: Owner direct record_payment succeeds. Admin/Accountant direct record_payment MUST FAIL. Their submit creates NO payments row. APPROVE creates exactly one payment. REJECT creates none. Request-key replay/conflict and overpayment revalidated at application time. Unapproved payment cannot satisfy Delivery.
-- MODULE RELEASE GATE: central approval engine alone does not gate Purchase/Return/other effects. Never claim those modules approval-protected until their final-effect RPC is explicitly wired and staging-tested.
-- RESULT: ROLE SECURITY ____ PERMISSION ADMIN ____ PAYMENT BYPASS ____ SELF APPROVAL ____ IDEMPOTENCY ____ DELIVERY GATE ____ OVERALL ____
