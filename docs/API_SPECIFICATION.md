# API Specification

Source of truth: `backend/routes/api.php` plus the 6 `FormRequest` validation classes under `backend/app/Http/Requests/`. Every route below is documented from those files directly, not from an earlier plan — see `docs/archive/novapay-backend-plan.md` (NOV-14) for the superseded early spec, which used different paths and a different schema entirely.

**Base URL:** `/api/v1` (all routes below are relative to this prefix).
**Auth scheme:** Laravel Sanctum bearer tokens. Authenticated routes require `Authorization: Bearer <token>`; unauthenticated requests to them get `401`.
**Content type:** JSON request and response bodies throughout.

---

## Rate limiting

| Limiter | Rate | Keyed by | Applied to |
|---|---|---|---|
| `login` | 5/min | `email + ip` | `POST /login` |
| `register` | 6/min | `ip` | `POST /register` |
| `user-search` | 10/min | authenticated user id (falls back to `ip`) | `GET /users/search` |
| `api` (general) | 60/min | authenticated user id (falls back to `ip`) | every route, applied globally via `throttleApi()` |

Exceeding a limit returns `429`. `user-search`'s limit is intentionally tighter than the general `api` limit — see NOV-22 — to reduce email-enumeration throughput on recipient lookup.

---

## Auth

### `POST /register`
**Auth:** none (`guest` middleware — rejects an already-authenticated request). **Rate limit:** `register`.

Request body (`RegisterRequest`):
| Field | Rules |
|---|---|
| `full_name` | required, string, max 255 |
| `email` | required, string, email, max 255, unique in `users` |
| `password` | required, string, min 8, must be confirmed (`password_confirmation` field) |

On success, creates the user **and two wallets in the same DB transaction** (a default USD wallet, `balance 0`, `is_default true`; a non-default KHR wallet, `balance 0`) — every user always has exactly these two wallets from registration onward, there is no "add a currency later" flow.

**201 response:**
```json
{
  "user": { "id": 1, "full_name": "...", "email": "...", "is_verified": false },
  "token": "<plain-text Sanctum token>",
  "token_type": "Bearer"
}
```
**422** on validation failure (standard Laravel validation error body).

### `POST /login`
**Auth:** none (`guest`). **Rate limit:** `login`.

Request body (`LoginRequest`): `email` (required, string, email), `password` (required, string).

**200 response:** same shape as register's success body (`user`, `token`, `token_type`), minus the `201` status.
**401** with `{"message": "The provided credentials are incorrect."}` — deliberately the same message whether the email doesn't exist or the password is wrong, to avoid confirming account existence.
**422** on validation failure.
**429** past the `login` limiter.

### `GET /me`
**Auth:** required.

**200 response:** `{"user": {...}}` (same `UserResource` shape as above) for the currently authenticated user.

### `POST /logout`
**Auth:** required.

Deletes only the current access token (`$request->user()->currentAccessToken()->delete()`) — other devices/sessions for the same user stay logged in.

**200 response:** `{"message": "Logged out successfully."}`

---

## Wallets

### `GET /wallets`
**Auth:** required.

Returns every wallet belonging to the authenticated user (always 2: USD + KHR, per registration behavior above).

**200 response:**
```json
{ "wallets": [ { "id": 1, "name": "...", "currency": "USD", "balance": 100.0, "is_default": true }, ... ] }
```

### `GET /wallets/default`
**Auth:** required.

**200:** `{"wallet": {...}}` (single `WalletResource`).
**404** if the user has no wallet flagged `is_default` (not expected in normal operation, but not DB-enforced either — see `docs/DATABASE_SCHEMA.md`).

---

## Transactions

### `GET /wallets/default/transactions`
**Auth:** required. Paginated, 20 per page (`?page=N`), newest first.

**200 response:**
```json
{
  "transactions": [
    { "id": 1, "type": "topup", "amount": 25.5, "balance_after": 125.5, "status": "completed", "description": "...", "related_wallet_id": null, "created_at": "..." }
  ],
  "meta": { "current_page": 1, "last_page": 1, "per_page": 20, "total": 1 }
}
```

### `GET /wallets/{currency}/transactions`
**Auth:** required. Same shape as above, scoped to whichever of the user's own wallets matches the `{currency}` path segment (`USD` or `KHR`).

**404** if the user has no wallet in that currency.

---

## Top-up

### `GET /payment-methods`
**Auth:** required.

Returns a fixed, hard-coded list (not database-backed — no real payment processor is integrated):
```json
{ "methods": [
  {"type": "linkedBank", "title": "Linked Bank", "subtitle": "•••• 1234", "iconAsset": "bank"},
  {"type": "debitCard", "title": "Debit Card", "subtitle": "•••• 4242", "iconAsset": "card"},
  {"type": "applePay", "title": "Apple Pay", "subtitle": "Secure & fast", "iconAsset": "apple_pay"}
] }
```

### `POST /topups`
**Auth:** required.

Request body (`StoreTopUpRequest`):
| Field | Rules |
|---|---|
| `amount` | required, decimal with 0-2 places, min `0.01` |
| `currency` | required, string, one of `USD`, `KHR` |
| `method` | required, string, one of `linkedBank`, `debitCard`, `applePay` |
| `idempotency_key` | required, string, max 64 |

Increments the user's wallet in that currency (row-locked for the duration of the DB transaction) and creates a `topup` transaction. See `docs/DATABASE_SCHEMA.md` for the idempotency-key uniqueness scoping (`idempotency_key, type, wallet_id`).

**201** `{"transaction": {...}}` (`TransactionResource`) on a genuine first-time success.
**200** `{"transaction": {...}}` — same shape, if `idempotency_key` was already used for this wallet (safe retry, no double-credit).
**404** if the user has no wallet in the requested currency.
**422** on validation failure.

### Notes on the archived early plan
The superseded `novapay-backend-plan.md` described `POST /api/wallet/topup` with a `method_id`, plus a separate `POST /api/wallet/withdraw`. Neither matches reality: the real path is `POST /api/v1/topups` with a `method` string enum (no `Card`/`LinkedAccount` records to reference an id from), and there is no withdraw endpoint at all.

---

## Transfers

### `POST /transfers`
**Auth:** required.

Request body (`StoreTransferRequest`):
| Field | Rules |
|---|---|
| `recipient_email` | required, email |
| `amount` | required, decimal with 0-2 places, min `0.01` |
| `currency` | required, string, one of `USD`, `KHR` |
| `idempotency_key` | required, string, max 64 |
| `note` | nullable, string, max 255 |

Moves money between the sender's and recipient's wallets of the same currency, inside one DB transaction with both wallet rows locked (ascending `id` order, to avoid deadlocking against an opposite-direction transfer running concurrently). Creates two transaction rows (`transfer_out` on the sender's wallet, `transfer_in` on the recipient's), sharing the same `idempotency_key`, each referencing the other's wallet via `related_wallet_id`.

**201** `{"transaction": {...}}` — the sender's `transfer_out` row.
**200** `{"transaction": {...}}` — same shape, on an idempotent replay.
**422** with `{"message": "You cannot transfer to yourself."}` if `recipient_email` matches the sender's own email (case-insensitive).
**422** with a `currency` validation error if the recipient has no wallet in the requested currency (no auto-creation — a hard block).
**422** with an `amount` validation error if the sender's balance is insufficient. The attempt is fully rolled back — no partial write, both wallets left exactly as they were.
**404** with `{"message": "No user found with that email."}` if `recipient_email` doesn't match any user.
**422** on request-validation failure.

---

## User search

### `GET /users/search`
**Auth:** required. **Rate limit:** `user-search` (10/min — see the rate-limiting section above).

Query parameter: `email` (required, valid email format).

**200** `{"user": {...}}` (`UserResource`) — an exact-match lookup by email, used for the transfer recipient picker. Deliberately not scoped to "people you've transacted with" — any authenticated user can look up any other user by their exact email. Confirmed to expose only safe fields (`id`, `full_name`, `email`, `is_verified` — never `password`). See `docs/ARCHITECTURE_AUDIT.md` finding L3 for the accepted privacy tradeoff this represents.
**404** with `{"message": "No user found with that email."}`.
**422** if `email` is missing or malformed.
**429** past the `user-search` limiter.

---

## Device tokens

### `POST /device-tokens`
**Auth:** required.

Request body (`StoreDeviceTokenRequest`): `token` (required, string, max 255), `platform` (optional, string, must be `android` if present — the only platform value currently accepted).

Registers (or re-registers) an FCM push token for the authenticated user. Because `token` is globally unique (not scoped per user — see `docs/DATABASE_SCHEMA.md`), registering a token already owned by a different user **reassigns it** to the current user rather than erroring — this is deliberate, for the same-device/different-login-session case.

**201** `{"message": "Device token registered."}`

### `DELETE /device-tokens`
**Auth:** required.

Request body (`DestroyDeviceTokenRequest`): `token` (required, string, max 255).

Deletes the token **only if it belongs to the authenticated user** — scoped via `$request->user()->deviceTokens()`. Deleting a token that exists but belongs to someone else is a silent no-op (0 rows affected), not an error.

**200** `{"message": "Device token removed."}` (returned regardless of whether a row was actually deleted).

---

## Common response envelope shapes

**`UserResource`:** `{id, full_name, email, is_verified}` — never includes `password` or any hashed credential.

**`WalletResource`:** `{id, name, currency, balance, is_default}` — `balance` is always a float in the JSON, even though it's `decimal(15,2)` in the database.

**`TransactionResource`:** `{id, type, amount, balance_after, status, description, related_wallet_id, created_at}`.

**Validation errors (422):** standard Laravel shape — `{"message": "...", "errors": {"field": ["..."]}}`.
