# TORVO V2 — GAP / COMPLETION NOTEBOOK

Status: INTERNAL DEVELOPMENT-CONTINUITY REGISTER — NOT A TORVO PRODUCT FEATURE
Updated: 2026-09-28
Branch: `torvo-v2-build`

## PURPOSE
Internal ChatGPT/development continuity register for gaps found while completing TORVO V2. This is NOT a TORVO app/website/admin feature and must never be exposed in product navigation or runtime UI. Do not hide or forget a gap because another feature is being developed. Move entries through OPEN -> IN PROGRESS -> SOURCE VERIFIED -> RUNTIME VERIFIED -> CLOSED. Runtime/external gates cannot be closed by source or CI alone. Never create fake users, transactions or evidence.

## OWNER EXECUTION RULE
- Work in the largest safe compatible bulk.
- Main TORVO V2 and Dealer Service Book progress in parallel.
- Preserve Owner-approved business logic.
- Ask Owner only for a genuine business decision, paid provider/API activation, irreversible security/production action, or required real-world acceptance.
- Production, main and V27 stay untouched without explicit approval.

## ACTIVE GAPS
| ID | Area | Gap / required completion | State | Blocking evidence / next action |
|---|---|---|---|---|
| G-001 | Dealer Auth | Genuine approved staging Dealer email-OTP + one-device runtime | OPEN | Needs genuine approved Dealer; no fake identity |
| G-002 | Staff Auth | Protected Owner browser runtime + genuine role boundary acceptance | PARTIAL | Genuine Owner exists; secondary roles must not be fabricated |
| G-003 | B2B | PO -> Sales Order -> Dealer OK -> Estimate -> fulfilment -> dispatch -> delivery | OPEN | Needs genuine staging transaction |
| G-004 | Purchase/Inventory/Returns | Receipt, stock movement, deduction, return/reversal reconciliation | OPEN | Needs genuine staging transaction |
| G-005 | Reports | Summary/detail reconciliation + role privacy | OPEN | Depends on accepted genuine transactions |
| G-006 | Backup/Restore | Real encrypted artifact + checksum + isolated restore rehearsal | OPEN | Real worker artifact/rehearsal required |
| G-007 | Android | Exact-SHA APK real-device install/login/business/UI evidence | OPEN | Physical Android acceptance required |
| G-008 | Android Production | Signing identity + release AAB/APK + store acceptance | OPEN | Owner/external release stage |
| G-009 | Production/Domain | Production backup/migrations/deploy/DNS/smoke | OPEN | Explicit Owner approval required |
| G-010 | Catalog Delete | Authorized destructive runtime behavior acceptance | OPEN | Real Owner/Admin staging test |
| G-011 | Service Book Runtime | Genuine Dealer job/media/search/complaint/parts/bill/status runtime | OPEN | Needs G-001 genuine Dealer |
| G-012 | Service Book Machine Identity | Reuse canonical TORVO catalog/master for structured Brand/Type/Model without duplicate master | IN PROGRESS | Wire existing dealer-safe catalog search; preserve controlled manual fallback |
| G-013 | Service Book Part Correction | Edit qty/selling rate on open job without weakening server rate authority | SOURCE VERIFIED | Exact source/CI revalidation after latest commits |
| G-014 | UI/UX Consistency | One TORVO RED/BLACK/WHITE/GREY system across Website/Admin/Accountant/Dealer/Salesman/Store | IN PROGRESS | Consolidate by dependency audit; do not blind-delete compatibility CSS |
| G-015 | Cleanup | Retire obsolete/duplicate paths only after dependency proof | OPEN | ACTIVE/RETIRED/SAFE-DELETE audit before deletion |

## VERIFIED RECENT WORK
- Service Book authoritative server dashboard counts.
- Private Dealer/device-bound Service Book media.
- Structured complaint master with Owner/Admin control.
- Closed-job server-authoritative bill and immutable delivered/cancelled records.
- Private history/customer/machine search.
- Open-job part remove and edit path; server remains authoritative for Dealer rate.
- Latest fully verified baseline before current work: `1db787767c844ef979e2846e2a589e4b17c41434` — Build #2992, Cloudflare #2323, Android #2281 SUCCESS.

## RULE FOR FUTURE BULKS
Every meaningful development bulk and every new-chat continuation should consult this register before choosing work. Add newly discovered gaps immediately. Close an entry only with the level of evidence its state requires. Update the Living Master when project truth changes; do not use this notebook to supersede canonical Owner rules.
