# TORVO V2 — Bill Allocation Posting Gates

The existing staging allocation table is locked against direct client writes. Do not enable posting until these conditions are implemented and tested.

1. Authenticate verified Owner/Admin/Accountant on the server.
2. Confirm estimate is a finalized sale, never a draft.
3. Confirm payment is received and belongs to that exact estimate and dealer.
4. Lock relevant records in one transaction to avoid concurrent over-allocation.
5. Reconcile historic receipts before introducing allocations, so they are not counted twice.
6. Reject allocations above payment balance or bill outstanding.
7. Use an idempotent request identifier and immutable audit records.
8. Provide authorized reversal, not deletion.
9. Run isolated staging integration tests before exposing any write RPC.

No live posting is enabled by this document.
