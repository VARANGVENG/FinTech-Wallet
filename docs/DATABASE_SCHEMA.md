# Database Schema

Source of truth: `backend/database/migrations/` (11 files as of 2026-09-30). This document is a manual cross-check against every one of them — table by table, including every `CHECK` constraint, unique index, and foreign key, not just a summary. For query paths and transaction/locking behavior built on top of this schema, see `docs/DATABASE_FLOW.md`.

**Engine:** MySQL (InnoDB). Money columns are `decimal(15,2)` everywhere — never float. `CHECK` constraints are added via raw `DB::statement()` calls (Laravel's schema builder has no first-class `CHECK` support), so they are MySQL-specific syntax, not portable to another database engine without rewriting.

---

## `users`

Migration: `0001_01_01_000000_create_users_table.php`.

| Column | Type | Constraints |
|---|---|---|
| `id` | bigint, PK, auto-increment | |
| `full_name` | string | |
| `email` | string | unique |
| `email_verified_at` | timestamp | nullable |
| `password` | string | hashed at the application layer (`User` model casts it) |
| `is_verified` | boolean | default `false` |
| `remember_token` | string (Laravel's `rememberToken()`) | nullable |
| `created_at` / `updated_at` | timestamps | |

**Relationships:** `hasMany(Wallet)`, `hasMany(Transaction)` (indirectly, through wallets), `hasMany(DeviceToken)`.

**Note:** there is no `pin`, `two_factor_enabled`, or `avatar_initials` column — those appeared in an early planning document (`docs/archive/novapay-backend-plan.md`, archived under NOV-14) that doesn't match what was actually built.

---

## `password_reset_tokens`

Migration: `0001_01_01_000000_create_users_table.php` (created alongside `users`, not its own migration).

| Column | Type | Constraints |
|---|---|---|
| `email` | string, PK | |
| `token` | string | |
| `created_at` | timestamp | nullable |

Laravel's standard password-reset table. Not currently wired to a real forgot-password flow in this app (no such route exists in `routes/api.php`).

---

## `sessions`

Migration: `0001_01_01_000000_create_users_table.php` (same file as `users`).

| Column | Type | Constraints |
|---|---|---|
| `id` | string, PK | |
| `user_id` | foreign id | nullable, indexed |
| `ip_address` | string(45) | nullable |
| `user_agent` | text | nullable |
| `payload` | longtext | |
| `last_activity` | integer | indexed |

Laravel's default session-driver table. This API is stateless (Sanctum bearer tokens via `personal_access_tokens`, below), so this table is framework scaffolding, not actually used by the mobile app's auth flow.

---

## `wallets`

Migrations: `2026_08_16_171245_create_wallets_table.php` (base table), `2026_08_27_090000_add_currency_to_wallets_table.php` (adds `currency`).

| Column | Type | Constraints |
|---|---|---|
| `id` | bigint, PK | |
| `user_id` | foreign id → `users.id` | `cascadeOnDelete()` |
| `name` | string | |
| `currency` | string | default `'USD'`, added after `name` |
| `balance` | decimal(15,2) | default `0` |
| `is_default` | boolean | default `false` |
| `created_at` / `updated_at` | timestamps | |

**Constraints (raw SQL, MySQL-specific):**
- `chk_wallets_balance_nonneg`: `CHECK (balance >= 0)`
- `chk_wallets_currency`: `CHECK (currency IN ('USD','KHR'))` — only two currencies are supported at the database level; adding a third requires a migration, not just an application-layer change.
- `uq_wallets_user_currency`: `UNIQUE (user_id, currency)` — a user can have at most one wallet per currency.

**Relationships:** `belongsTo(User)`, `hasMany(Transaction)` (as the owning wallet), `hasMany(Transaction, 'related_wallet_id')` (as the counterparty wallet in a transfer).

**Not enforced at the database level:** exactly one `is_default = true` wallet per user is an application-level expectation, not a DB constraint — nothing stops two wallets for the same user both having `is_default = true` at the schema level.

---

## `transactions`

Migrations: `2026_08_24_151834_create_transactions_table.php` (base table), `2026_08_27_090100_add_idempotency_key_to_transactions_table.php` (adds `idempotency_key`), `2026_08_29_085448_make_idempotency_key_unique_per_type.php`, `2026_09_28_105533_scope_idempotency_key_uniqueness_to_wallet.php` (both narrow the idempotency uniqueness — see below).

| Column | Type | Constraints |
|---|---|---|
| `id` | bigint, PK | |
| `wallet_id` | foreign id → `wallets.id` | `cascadeOnDelete()` |
| `related_wallet_id` | foreign id → `wallets.id` | nullable, `nullOnDelete()` |
| `type` | string | |
| `amount` | decimal(15,2) | |
| `balance_after` | decimal(15,2) | |
| `status` | string | |
| `idempotency_key` | string | nullable, added after `status` |
| `description` | string | nullable |
| `created_at` / `updated_at` | timestamps | |

**Indexes:** `(wallet_id, created_at)` — supports the paginated transaction-history query (`$wallet->transactions()->latest()->paginate(20)`).

**Constraints (raw SQL, MySQL-specific):**
- `chk_transactions_type`: `CHECK (type IN ('topup','transfer_in','transfer_out'))`
- `chk_transactions_amount_positive`: `CHECK (amount > 0)`
- `chk_transactions_balance_after_nonneg`: `CHECK (balance_after >= 0)`
- `chk_transactions_status`: `CHECK (status IN ('pending','completed'))` — note `failed`/`on_hold` (mentioned in the archived early planning doc) don't exist here; this app has no failure-status transaction path today.

**The idempotency unique index has changed twice — this is the most important part of this table to understand precisely:**

1. **2026-08-27:** `idempotency_key` added, globally unique on its own (`UNIQUE (idempotency_key)`).
2. **2026-08-29:** narrowed to `UNIQUE (idempotency_key, type)` — necessary because a single transfer legitimately creates *two* rows (`transfer_in` and `transfer_out`) sharing the same key, which a bare-column unique index would have rejected as a duplicate.
3. **2026-09-28 (NOV-21):** narrowed again to `UNIQUE (idempotency_key, type, wallet_id)`. Reason: `(idempotency_key, type)` alone was unique *across every user's wallet*, so a key collision between two different users (a replay, a guess, or a genuine UUID collision) made the idempotency pre-check and MySQL's own 1062-duplicate-key recovery path both match the *first* user's row — leaking their transaction data to the second user, and for top-ups, silently skipping crediting the second user's own wallet. Scoping the constraint to `wallet_id` closes this at the schema level: two different users can never share a `wallet_id`, so their idempotency keys can never collide, regardless of what the application-layer query does. See `TransferController::store()` and `TopUpController::store()` for the corresponding query-level scoping added in the same change.

**Relationships:** `belongsTo(Wallet)` (the owning wallet), `belongsTo(Wallet, 'related_wallet_id')` (the counterparty wallet, `relatedWallet()`).

---

## `device_tokens`

Migration: `2026_09_12_100000_create_device_tokens_table.php`.

| Column | Type | Constraints |
|---|---|---|
| `id` | bigint, PK | |
| `user_id` | foreign id → `users.id` | `cascadeOnDelete()` |
| `token` | string | **globally unique**, not scoped to `user_id` |
| `platform` | string | default `'android'` |
| `last_used_at` | timestamp | nullable |
| `created_at` / `updated_at` | timestamps | |

**Why `token` is globally unique rather than unique per user:** a token identifies one physical device install, not a user. If a different user logs into the same phone, `DeviceTokenController::store()` re-registers that same token value to the new user (an explicit `updateOrCreate` keyed only on `token`) rather than creating a second row — otherwise the previous user would keep receiving push notifications meant for the new one.

**Relationships:** `belongsTo(User)`.

---

## `personal_access_tokens`

Migration: `2026_08_13_120330_create_personal_access_tokens_table.php`.

Laravel Sanctum's standard token table.

| Column | Type | Constraints |
|---|---|---|
| `id` | bigint, PK | |
| `tokenable_type` / `tokenable_id` | morphs | polymorphic owner (here, always a `User`) |
| `name` | text | |
| `token` | string(64) | unique, stored hashed |
| `abilities` | text | nullable |
| `last_used_at` | timestamp | nullable |
| `expires_at` | timestamp | nullable, indexed |
| `created_at` / `updated_at` | timestamps | |

**Note:** `expires_at` is nullable and never set by `AuthController` — tokens are issued without an explicit expiration (see `docs/ARCHITECTURE_AUDIT.md`, finding M5).

---

## Framework infrastructure tables (not application domain data)

These exist for Laravel's own subsystems, not modeled by any app-specific Eloquent model:

| Table | Migration | Purpose |
|---|---|---|
| `cache`, `cache_locks` | `0001_01_01_000001_create_cache_table.php` | Laravel's database cache driver |
| `jobs`, `job_batches`, `failed_jobs` | `0001_01_01_000002_create_jobs_table.php` | Laravel's queue system — this is where `SendPushNotificationJob` rows land while `QUEUE_CONNECTION=database` |

---

## Entity relationship summary

```
users 1──* wallets 1──* transactions *──1 wallets (related_wallet_id, self-referential via the transactions table)
users 1──* device_tokens
users 1──* personal_access_tokens (polymorphic, via tokenable_*)
```

A transfer is represented as two `transactions` rows (one `transfer_out` on the sender's wallet, one `transfer_in` on the recipient's wallet), linked by a shared `idempotency_key` and each pointing at the other's wallet via `related_wallet_id` — there is no separate `transfers` table.
