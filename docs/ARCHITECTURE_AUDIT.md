# Architecture Audit Findings

## CRITICAL

No critical issue was confirmed. The core financial write paths use transactions, row locks, constraints, and idempotency keys.

## HIGH

### H1. Database configuration conflicts with financial assumptions

References: `backend/.env.example`, `backend/phpunit.xml`, `.github/workflows/backend-tests.yml`, `TopUpController::store()`, `TransferController::store()`.

`.env.example` defaults to SQLite, while tests/CI use MySQL and idempotency race handling checks MySQL error code `1062`. Financial correctness depends on database behavior, so the supported local/test/production engine should be aligned.

### H2. Financial business logic lives in controllers

References: `backend/app/Http/Controllers/Api/V1/TopUpController.php`, `backend/app/Http/Controllers/Api/V1/TransferController.php`.

Top-up and transfer controllers contain validation handoff, idempotency, wallet locking, balance mutation, ledger row creation, duplicate-key handling, and response construction. It works now, but the controller layer is doing domain-service work.

### H3. Fraud alert feature is simulated but presented as a real workflow

References: `frontend/lib/features/fraud/data/datasource/fraud_remote_datasource.dart`, `frontend/lib/core/network/api_endpoints.dart`, `backend/routes/api.php`.

The fraud datasource returns hard-coded delayed JSON. Laravel has no fraud routes, controllers, models, migrations, or persisted state. This is a product/security mismatch if exposed as real user action.

## MEDIUM

### M1. Submit loading state never turns on for top-up or transfer

References: `frontend/lib/features/topup/presentation/provider/topup_provider.dart`, `frontend/lib/features/transfer/presentation/provider/transfer_provider.dart`.

Both `submit()` methods set `submitting: false` before the network request. Confirm buttons depend on `state.submitting`, so users do not get a true loading state and duplicate tapping risk increases.

### M2. Flutter ignores transaction pagination metadata

References: `TransactionController::respondWithPage()`, `TransactionRemoteDataSource`.

The backend returns paginated data with `meta`, but Flutter only parses the first `transactions` list. Users cannot load page 2+.

### M3. Field-level validation errors are lost on the frontend

Reference: `frontend/lib/core/network/api_client.dart`.

`ApiClient._mapError()` extracts top-level `message` only. Laravel validation error bags under `errors` are not surfaced.

### M4. Endpoint constants exceed backend contract

References: `frontend/lib/core/network/api_endpoints.dart`, `backend/routes/api.php`.

Constants exist for transaction detail, report issue, fraud alerts, and settings. The backend does not implement those routes.

### M5. Token lifecycle is incomplete

References: `AuthController`, `SecureStorageService`.

Sanctum tokens are created without explicit expiration. `SecureStorageService` has refresh-token methods, but no refresh endpoint or refresh flow exists.

## LOW

### L1. Empty app/router/environment files create architecture ambiguity

References: `frontend/lib/app/app.dart`, `frontend/lib/app/router.dart`, `frontend/lib/app/environment.dart`, `frontend/lib/main.dart`.

The runtime app is in `main.dart`, not the empty app/router files. Future developers may look in the wrong place first.

### L2. Stale mock transaction file remains

Reference: `frontend/lib/core/mock/mock_transaction_history.dart`.

Real transaction history is now API-backed through providers, but old mock data remains.

### L3. Recipient search reveals email existence

Reference: `UserController::search()`.

Any authenticated user can query whether an exact email exists and receive id/name/email. This may be acceptable for transfers, but it is a deliberate privacy tradeoff.

### L4. Frontend tests are thin

Reference: `frontend/test/widget_test.dart`.

No feature/provider/repository tests were found for auth, wallets, top-up, transfer, transactions, settings, or fraud.

## INFORMATIONAL

### I1. Backend feature tests are strong for current scope

References: `backend/tests/Feature/*`.

Tests cover auth, scoping, transaction pagination, top-up, transfer, idempotency, lock ordering, user search, and rate limits.

### I2. No backend services/repositories exist

References: `backend/app/Http/Controllers/Api/V1/*`, `backend/app/Models/*`.

This is not inherently wrong for a small codebase, but it is the main future architecture refactor candidate.
