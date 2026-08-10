# NovaPay Laravel Backend — Full Build Plan

This plan maps every screen you shared to concrete database tables and API endpoints, so when we start coding, we're implementing a spec instead of guessing as we go.

---

## 1. Architecture overview

- **Laravel 13** as a pure JSON API (no Blade views needed for the mobile app)
- **Sanctum** for token-based auth (Flutter sends `Authorization: Bearer <token>`)
- **MySQL** for the database
- Money stored as `decimal(15,2)` everywhere — never float
- Every money-moving action wrapped in a `DB::transaction()` so a crash can't leave a wallet half-updated
- API responses shaped with **Laravel API Resources**, so the JSON structure is stable and intentional, not "whatever Eloquent happens to return"

---

## 2. Database schema

### `users`
Standard Laravel users table plus fintech-specific fields.

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| full_name | string | shown as "Alex Morgan" |
| email | string, unique | |
| password | string (hashed) | |
| pin | string (hashed) | for "Change PIN" in settings |
| is_verified | boolean | "✓ Verified" badge on Profile |
| two_factor_enabled | boolean | |
| biometric_enabled | boolean | toggle in Settings, verified client-side but tracked server-side |
| avatar_initials | string | e.g. "VR" if no photo |
| created_at / updated_at | timestamps | |

### `wallets`
One wallet per user (could support multiple currencies later, but start with one).

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| user_id | FK → users | |
| balance_available | decimal(15,2) | "Available $9,850.20" |
| balance_pending | decimal(15,2) | "Pending $2,600.55" |
| currency | string(3) | default USD |

*Why split available/pending instead of one balance field:* your dashboard shows both numbers separately, and a transfer that's "processing" shouldn't be spendable yet. Total balance shown on the dashboard = `available + pending`.

### `cards`
Separate from wallet — a user can have multiple linked cards (Visa •••• 4242 shown on Wallet and Top-up screens).

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| user_id | FK → users | |
| brand | string | "VISA" |
| last_four | string(4) | "4242" |
| is_default | boolean | |
| type | enum | `debit`, `credit` |

### `linked_accounts`
For "Linked Bank" shown in Top-up and "Linked Accounts" in Profile.

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| user_id | FK → users | |
| bank_name | string | |
| account_last_four | string(4) | |
| is_verified | boolean | |

### `transactions`
The core ledger. Covers deposits, withdrawals, purchases (Starbucks, Amazon, Netflix), and transfers.

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| wallet_id | FK → wallets | |
| type | enum | `deposit`, `withdrawal`, `transfer_out`, `transfer_in`, `purchase` |
| merchant | string, nullable | "Starbucks Coffee", "Amazon Marketplace" |
| category | string, nullable | "Food & Drinks" |
| amount | decimal(15,2) | |
| status | enum | `pending`, `completed`, `failed`, `on_hold` |
| reference | string, unique | "TXN-8293748" |
| payment_method | string, nullable | "VISA •••• 4242" |
| flagged | boolean, default false | drives the Fraud Alert screen |
| created_at | timestamp | shown as "Today, 9:42 AM" |

*Why `on_hold` as a status, not just a boolean:* the Fraud Alert screen shows a transaction that's neither completed nor failed — it's suspended pending the user's response. Modeling it as a distinct status keeps the state machine honest.

### `transfers`
A transfer is really two transaction rows (money out of one wallet, into another) linked by one transfer record — this is what powers the Transfer → Confirm → Result flow and gives you a single reference ID to show on both sides.

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| sender_wallet_id | FK → wallets | |
| recipient_wallet_id | FK → wallets | |
| amount | decimal(15,2) | |
| note | string, nullable | "Dinner payment" |
| reference | string, unique | "TRF-982475-09" |
| status | enum | `pending`, `completed`, `failed` |

### `disputes`
Powers "This wasn't me" / "It was me" on the Fraud Alert screen.

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| transaction_id | FK → transactions | |
| user_id | FK → users | |
| status | enum | `reported`, `confirmed_legit`, `investigating`, `resolved` |
| resolution_note | text, nullable | |

### `documents`
For the "Documents" item in Profile (likely KYC docs — ID, proof of address).

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| user_id | FK → users | |
| type | string | "ID Card", "Proof of Address" |
| file_path | string | |
| status | enum | `pending`, `approved`, `rejected` |

### `notification_settings`
Backs the toggles on the Settings screen (Push Notifications, Transaction Alerts, Biometric Login, Dark Mode — dark mode is really a client preference but syncing it server-side keeps it consistent across devices).

| Column | Type | Notes |
|---|---|---|
| id | bigint | |
| user_id | FK → users | |
| push_notifications | boolean | |
| transaction_alerts | boolean | |
| biometric_login | boolean | |
| dark_mode | boolean | |

---

## 3. API endpoints, mapped to each screen

### Auth
| Screen | Endpoint |
|---|---|
| Login | `POST /api/login` |
| Register | `POST /api/register` |
| Login → Forgot? | `POST /api/forgot-password`, `POST /api/reset-password` |

### Home Dashboard
| Screen | Endpoint |
|---|---|
| Hello, Alex + Total Balance | `GET /api/dashboard` → returns user name, `balance_available`, `balance_pending` |
| Recent Activity | `GET /api/transactions?limit=4` |

### Wallet
| Screen | Endpoint |
|---|---|
| Wallet balance + card | `GET /api/wallet` |
| Transaction History + Filter | `GET /api/transactions?type=&status=&from=&to=` |

### Top-up
| Screen | Endpoint |
|---|---|
| Load amount options / methods | `GET /api/funding-methods` (cards + linked banks) |
| Review Top-up → confirm | `POST /api/wallet/topup` `{ amount, method_id }` |

### Withdraw
| Screen | Endpoint |
|---|---|
| Withdraw | `POST /api/wallet/withdraw` `{ amount, method_id }` |

### Transfer flow
| Screen | Endpoint |
|---|---|
| Recipient search | `GET /api/users/search?query=` |
| Transfer → Continue | validated client-side, no call yet (just moves to confirm screen) |
| Confirm Transfer | `POST /api/transfers` `{ recipient_id, amount, note }` → returns reference, triggers both wallets updating in one DB transaction |
| Transfer Result / View Receipt | `GET /api/transfers/{reference}` |

### Transaction Detail
| Screen | Endpoint |
|---|---|
| Transaction Detail | `GET /api/transactions/{id}` |
| Report an Issue | `POST /api/transactions/{id}/report` |

### Fraud Alert
| Screen | Endpoint |
|---|---|
| Load flagged transaction | `GET /api/disputes/{id}` |
| "This wasn't me" | `POST /api/disputes/{id}/reject` → status becomes `investigating`, transaction stays `on_hold`, could trigger card freeze |
| "It was me" | `POST /api/disputes/{id}/confirm` → status becomes `resolved`, transaction becomes `completed` |

### Profile
| Screen | Endpoint |
|---|---|
| Profile info | `GET /api/profile` |
| Personal Information | `PUT /api/profile` |
| Security | `GET /api/security-settings` |
| Linked Accounts | `GET /api/linked-accounts`, `POST /api/linked-accounts` |
| Documents | `GET /api/documents`, `POST /api/documents` (file upload) |
| Logout | `POST /api/logout` (revokes the Sanctum token) |

### Settings
| Screen | Endpoint |
|---|---|
| Toggles (push, alerts, biometric, dark mode) | `GET /api/settings`, `PATCH /api/settings` |
| Change PIN | `POST /api/settings/change-pin` |
| Change Password | `POST /api/settings/change-password` |
| Two-Factor Authentication | `GET /api/2fa/status`, `POST /api/2fa/enable`, `POST /api/2fa/disable` |

---

## 4. Fraud flagging approach (keep it simple at first)

For a junior-level build, don't reach for machine learning. A rule-based check run right when a transaction is created is enough to start:

- Flag if amount is unusually large compared to the user's recent average
- Flag if it's from a new/unrecognized merchant category combined with a large amount
- Flag if multiple transactions occur in a very short time window

This can live in a simple `FraudCheckService` class that `TransactionController` calls after creating a transaction, setting `flagged = true` and `status = on_hold` when triggered.

---

## 5. Suggested build order

1. **Phase 1 — Foundation:** migrations for all tables above, models, relationships
2. **Phase 2 — Auth:** register/login/logout with Sanctum, profile endpoints
3. **Phase 3 — Wallet & Transactions:** dashboard, wallet, transaction history, transaction detail
4. **Phase 4 — Top-up & Withdraw:** funding methods, balance updates
5. **Phase 5 — Transfers:** recipient search, transfer creation, confirmation, receipts
6. **Phase 6 — Fraud & Disputes:** flagging logic, dispute endpoints
7. **Phase 7 — Settings & Security:** toggles, PIN/password change, 2FA

Each phase is independently testable with Postman before moving to the next — so we're never debugging five features at once.

---

## 6. Folder structure (Laravel 13, slim structure)

```
app/
├── Models/            (User, Wallet, Card, Transaction, Transfer, Dispute, ...)
├── Http/
│   ├── Controllers/Api/   (AuthController, WalletController, TransferController, ...)
│   ├── Resources/         (WalletResource, TransactionResource, ...)
│   └── Requests/          (TopUpRequest, TransferRequest, ... - validation)
├── Services/           (FraudCheckService, TransferService)
routes/
└── api.php
database/
└── migrations/
```

Using `Services/` for things like transfer logic keeps controllers thin — a controller just validates input and calls a service, which is easier to test and reuse.
