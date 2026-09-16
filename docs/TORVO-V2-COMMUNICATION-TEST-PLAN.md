# TORVO V2 COMMUNICATION TEST PLAN

## TEST 1 — PUBLIC CONTACT
Confirm public Website shows only enabled public business contact data and never exposes PRIVATE_ADMIN_EMAIL.

## TEST 2 — SOCIAL REQUIREMENT
Open a configured social entry link, reach TORVO requirement flow, submit a test requirement, and verify source attribution is retained only when actually supplied/known.

## TEST 3 — WHATSAPP
With staging provider credentials, trigger an allowed operational WhatsApp action. Confirm TORVO records success only after real provider acknowledgement; verify failure/retry states are truthful.

## TEST 4 — CONSENT
Submit a requirement without marketing opt-in. Confirm the lead can be serviced but is excluded from promotional messaging. Then test explicit opt-in and subsequent opt-out.

## TEST 5 — ROLE + PRIVACY
Test Customer, Dealer, Salesman, Store Keeper, Accountant, Admin and Owner access. Confirm private Admin email/provider credentials are inaccessible to unauthorized roles and blocked/inactive accounts cannot execute private communication actions.

## PASS CONDITION
All five tests must pass in staging with real configured integrations where required before communication features are marked production-ready.
