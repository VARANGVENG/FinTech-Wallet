# ADR 0002: Scope the idempotency-key unique constraint to (key, type, wallet)

**Status:** Accepted (evolved through 3 revisions)

## Context

Top-up and transfer are the two money-moving write endpoints. Both accept a client-generated `idempotency_key` so a retried or double-tapped request doesn't move money twice. Enforcing this correctly requires a database-level uniqueness guarantee, not just an application-layer check (a pure application check has a race window between the check and the insert).

## Decision

The `transactions` table's idempotency uniqueness constraint went through three stages, each fixing a real problem the previous one didn't anticipate:

1. **`UNIQUE(idempotency_key)` alone** (2026-08-27, first implementation).
2. **`UNIQUE(idempotency_key, type)`** (2026-08-29). A single transfer legitimately creates *two* transaction rows — `transfer_out` on the sender's wallet and `transfer_in` on the recipient's — sharing the same key. A bare-column unique index rejected the second row as a duplicate of the first; scoping by `type` as well allows both to coexist while still catching a genuine retry of the same operation.
3. **`UNIQUE(idempotency_key, type, wallet_id)`** (2026-09-28, NOV-21). `(idempotency_key, type)` alone was unique *across every user's wallets*, not just one user's. A key collision between two different users' requests — a replay, a guess, or a genuine UUID collision — made the idempotency pre-check and MySQL's own 1062-duplicate-key recovery path both match the *first* user's row, returning their transaction data to the second user and, for top-ups, silently skipping crediting the second user's own wallet. Adding `wallet_id` to the constraint closes this at the schema level: two different users can never share a `wallet_id`, so their keys can never collide, independent of whatever the application-layer query does.

Each controller (`TransferController`, `TopUpController`) has two code paths that rely on this constraint: a pre-check query (`Transaction::where('idempotency_key', ...)`) that short-circuits an exact replay before attempting the DB transaction, and a `QueryException` recovery path (checking for MySQL error code 1062) that handles two requests racing past the pre-check simultaneously. Both paths were updated to also scope by the requesting user's wallet when the constraint changed.

## Consequences

**Positive:** the uniqueness guarantee now lives in the schema, not just application logic — even a bug in the query-level scoping cannot cause a cross-user collision, because the database itself cannot represent two different users sharing a `wallet_id`.

**Accepted limitation:** this proves replay/duplicate-request handling is correct, and that MySQL genuinely enforces the constraint (verified directly against real MySQL, not SQLite — see `docs/ARCHITECTURE_AUDIT.md` finding H1 on why that distinction matters here). It does **not** prove true concurrent-race safety — two requests genuinely overlapping in time — which is structurally difficult to test deterministically in a sequential PHPUnit process. This was evaluated (NOV-23) and accepted as a known, deliberate gap rather than missed.

**Portability cost:** the constraint's practical safety depends on catching MySQL's specific error code 1062; porting to a different database engine would require updating that check, not just the migration.
