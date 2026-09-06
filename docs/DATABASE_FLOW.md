# Database Flow

## Tables and Models

### users

Migration: `backend/database/migrations/0001_01_01_000000_create_users_table.php`.

Columns include `id`, `full_name`, unique `email`, nullable `email_verified_at`, `password`, `is_verified`, `remember_token`, and timestamps. `User` hides password and remember token, casts password as hashed, and defines `wallets(): HasMany`.

### wallets

Migrations: `2026_08_16_171245_create_wallets_table.php` and `2026_08_27_090000_add_currency_to_wallets_table.php`.

Columns include `id`, `user_id`, `name`, `currency`, `balance decimal(15,2)`, `is_default`, timestamps. Constraints include `balance >= 0`, `currency IN ('USD','KHR')`, FK `user_id`, and unique `(user_id, currency)`. `Wallet` casts `balance` decimal:2 and `is_default` boolean, and defines `user()` plus `transactions()`.

### transactions

Migrations: `2026_08_24_151834_create_transactions_table.php`, `2026_08_27_090100_add_idempotency_key_to_transactions_table.php`, and `2026_08_29_085448_make_idempotency_key_unique_per_type.php`.

Columns include `id`, `wallet_id`, nullable `related_wallet_id`, `type`, `amount`, `balance_after`, `status`, `idempotency_key`, `description`, timestamps. Constraints/indexes include FK wallet links, index `(wallet_id, created_at)`, positive amount, nonnegative `balance_after`, allowed type/status checks, and unique `(idempotency_key, type)`. `Transaction` casts amount fields to decimal:2 and defines `wallet()` plus `relatedWallet()`.

## Query Paths

Wallet list: `$request->user()->wallets()->get()`.

Default wallet: `$request->user()->wallets()->where('is_default', true)->firstOrFail()`.

Transactions: `$wallet->transactions()->latest()->paginate(20)`.

Top-up: authenticated user's wallet is queried by currency, locked with `lockForUpdate()`, incremented, and used to create a `topup` transaction.

Transfer: sender and recipient wallet IDs are found by currency, both wallet rows are loaded with `Wallet::whereIn(...)->orderBy('id')->lockForUpdate()`, balances are mutated, and two transaction rows are created.

## Financial Consistency

Registration, top-up, and transfer use `DB::transaction()`. Top-up locks the one wallet row before incrementing. Transfer locks both wallets in ascending ID order before checking balance or mutating balances. This is the strongest consistency choice found in the code.

Idempotency uses a client UUID. Top-up checks any transaction by key. Transfer checks `transfer_out` by key/type because a legitimate transfer writes both `transfer_in` and `transfer_out` rows with the same key. Raced duplicates are handled by the unique `(idempotency_key, type)` constraint and MySQL duplicate-key code `1062`.

## Database Risks

- `.env.example` says SQLite, but financial correctness tests and duplicate-key handling assume MySQL.
- Raw constraint SQL in migrations is database-specific.
- No explicit transaction isolation level is configured.
- Mutable wallet balance is the live source of truth; transaction rows are the supporting ledger/audit trail.
- `idempotency_key` is nullable in the schema, though API write flows require it.
