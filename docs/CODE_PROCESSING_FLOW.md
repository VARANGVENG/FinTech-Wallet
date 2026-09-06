# NovaPay - Complete Code Processing Flow

## 1. Project Overview

Audit workspace:

- Original project path: `D:\AMobile App Doc\fintech_wallet`
- Clone path: `D:\NovaPay_Code_Audit`
- Git branch audited: `feature/topup`
- Git commit audited: `9a3342a73caa8dd74ce89f67a595ff57477e0dfb`
- Clone result: successful local Git clone, then current working-tree overlay excluding `.git` so uncommitted/untracked source is included.
- Original project: not modified by this audit.

Implemented backend features: registration, login, current user, logout, wallets, default wallet, per-currency wallets, transaction history, payment methods, top-up, recipient search, and transfer.

Implemented frontend features include the above API-backed flows plus profile, settings, notifications, and fraud alert screens. Settings are local-only. Alert notifications and fraud are mock/simulated. No Laravel routes exist for fraud alerts, settings, transaction detail, or report issue.

## 2. Technology Stack

Frontend: Flutter/Dart, Riverpod, Dio, Flutter Secure Storage, SharedPreferences, UUID. `frontend/pubspec.yaml` requires Dart `^3.11.5`. CI uses Flutter `3.41.9` in `.github/workflows/analyze.yml`. Local `flutter --version` and `dart --version` hung with no output and were stopped.

Backend: Laravel, PHP, Sanctum, Eloquent, PHPUnit. `backend/composer.json` requires PHP `^8.3`, Laravel `^13.8`, Sanctum `^4.0`. Local PHP is `8.3.14`; `php artisan --version` reports Laravel `13.24.0`. CI uses MySQL 8.0. `.env.example` defaults to SQLite.

## 3. Actual Project Architecture

Frontend architecture is feature-first and mostly Clean Architecture shaped:

```text
Screen / Widget
  -> Riverpod Provider / StateNotifier / FutureProvider
  -> Domain Repository Interface
  -> Data Repository Implementation
  -> Remote Datasource or Local Storage Repository
  -> Core ApiClient / Storage Service
```

Backend architecture is Laravel route/controller/model oriented:

```text
public/index.php
  -> bootstrap/app.php
  -> routes/api.php
  -> middleware
  -> controller method
  -> Form Request validation where present
  -> Eloquent model / DB::transaction
  -> API Resource
  -> JSON response
```

Important difference from the expected architecture: the backend does not currently have service or repository layers for financial features. `TopUpController::store()` and `TransferController::store()` contain business logic directly.

## 4. Folder Structure and Communication

Frontend:

- `frontend/lib/main.dart`: true app entry point and startup auth gate.
- `frontend/lib/app/main_navigation.dart`: bottom navigation and page switching.
- `frontend/lib/app/constants.dart`: app colors/constants.
- `frontend/lib/app/app.dart`, `router.dart`, `environment.dart`: empty placeholders in the audited code.
- `frontend/lib/core/network`: `ApiClient`, `ApiEndpoints`, `AuthInterceptor`.
- `frontend/lib/core/storage`: secure token storage and local JSON preferences.
- `frontend/lib/core/providers`: Riverpod providers for storage and API client.
- `frontend/lib/features/*`: feature-first UI/domain/data code.
- `frontend/lib/shared/widgets`: reusable UI widgets.

Backend:

- `backend/public/index.php`: HTTP entry.
- `backend/bootstrap/app.php`: modern Laravel routing, middleware, JSON exception config.
- `backend/bootstrap/providers.php`: registers `AppServiceProvider`.
- `backend/routes/api.php`: all implemented API routes.
- `backend/app/Http/Controllers/Api/V1`: API controllers.
- `backend/app/Http/Requests`: Form Request validation.
- `backend/app/Http/Resources`: JSON transformers.
- `backend/app/Models`: `User`, `Wallet`, `Transaction`.
- `backend/database/migrations`: schema, indexes, constraints.
- `backend/tests/Feature`: backend API tests.

## 5. Overall System Architecture

```text
Flutter UI
  -> Riverpod state
  -> Repository interface
  -> Repository implementation
  -> Remote datasource
  -> ApiClient / Dio
  -> HTTP JSON
  -> Laravel /api/v1 route
  -> Middleware: guest, auth:sanctum, throttle
  -> Controller
  -> Form Request validation
  -> Eloquent relationship/query/transaction
  -> MySQL/SQLite configured database
  -> API Resource
  -> JSON response
  -> Dio Map<String,dynamic>
  -> Model.fromJson
  -> Provider state
  -> Widget rebuild or navigation
```

## 6. Flutter Lifecycle

`main()` in `frontend/lib/main.dart` initializes bindings, awaits `LocalStorageService.create()`, overrides `localStorageProvider`, and renders `MyApp`. `_StartupGate` checks `SecureStorageService.isLoggedIn`. If no token exists, it shows `LoginScreen`; if a token exists, it calls `AuthNotifier.restoreSession()` and then shows `MainNavigation` if the token remains.

`ApiClient` in `frontend/lib/core/network/api_client.dart` owns the shared Dio instance. It sets `ApiEndpoints.baseUrl`, JSON content type, 15-second timeouts, and `AuthInterceptor`. `AuthInterceptor` reads the secure token before each request and adds `Authorization: Bearer <token>`. On `401`, it clears local tokens; the configured callback is currently a placeholder.

## 7. Laravel Lifecycle

This project uses modern Laravel structure. There is no `app/Http/Kernel.php` in the audited code.

`backend/bootstrap/app.php` configures web/API/console/health routes, enables API throttling, and renders JSON for `api/*` exceptions. `AppServiceProvider::boot()` disables resource wrapping and defines rate limiters: login 5/min by email+IP, register 6/min by IP, general API 60/min by user id or IP.

## 8. Authentication Flow

```text
LoginScreen/RegisterScreen
  -> AuthNotifier.login/register
  -> AuthRepositoryImpl
  -> AuthRemoteDataSource
  -> ApiClient.post('/login' or '/register')
  -> routes/api.php
  -> AuthController::login/register
  -> LoginRequest/RegisterRequest
  -> User model / Sanctum token
  -> UserResource + token JSON
  -> UserModel.fromJson
  -> SecureStorageService.saveAuthToken
  -> AuthState.success
```

Registration wraps `User::create()` and creation of USD/KHR wallets in `DB::transaction()`. Login returns a generic `401` for both wrong password and unknown email.

## 9. Wallet and Transaction Flow

Wallet:

```text
HomeDashboardScreen / WalletScreen
  -> walletProvider or walletsProvider
  -> WalletRepositoryImpl
  -> WalletRemoteDataSource
  -> GET /wallets/default or /wallets
  -> WalletController::default/index
  -> $request->user()->wallets()
  -> WalletResource
  -> WalletModel
```

Transactions:

```text
BalanceOverviewScaffold
  -> transactionHistoryProvider or walletTransactionsProvider(currency)
  -> TransactionRepositoryImpl
  -> TransactionRemoteDataSource
  -> GET /wallets/default/transactions or /wallets/{currency}/transactions
  -> TransactionController::index/byCurrency
  -> $wallet->transactions()->latest()->paginate(20)
  -> TransactionResource collection + meta
  -> TransactionModel.fromJson
  -> CustomTransactionHistoryItem
```

The API paginates results and returns `meta`, but Flutter currently parses only the `transactions` list.

## 10. Top-up Flow

```text
TopUpScreen.initState
  -> TopUpNotifier.loadPaymentMethods
  -> TopUpRepositoryImpl.getPaymentMethods
  -> TopUpRemoteDataSource.getPaymentMethods
  -> GET /payment-methods
  -> TopUpController::methods fixed list

ConfirmTopUpScreen._handleConfirm
  -> TopUpNotifier.submit
  -> TopUpRepositoryImpl.submitTopUp
  -> TopUpRemoteDataSource.submitTopUp
  -> POST /topups {amount,currency,method,idempotency_key}
  -> StoreTopUpRequest
  -> TopUpController::store
  -> Transaction pre-check by idempotency_key
  -> DB::transaction
  -> user's currency wallet with lockForUpdate
  -> increment balance
  -> create topup transaction
  -> TransactionResource JSON
  -> invalidate walletProvider and transactionHistoryProvider
  -> TopUpResultScreen
```

## 11. Transfer Flow

```text
RecipientPickerSheet._search
  -> TransferRepositoryImpl.findRecipient
  -> TransferRemoteDataSource.findRecipient
  -> GET /users/search?email=...
  -> UserController::search
  -> UserResource
  -> Recipient.fromJson

ConfirmTransferScreen._handleConfirm
  -> TransferNotifier.submit
  -> TransferRepositoryImpl.submitTransfer
  -> TransferRemoteDataSource.submitTransfer
  -> POST /transfers {recipient_email,amount,currency,idempotency_key,note?}
  -> StoreTransferRequest
  -> TransferController::store
  -> self-transfer check
  -> recipient lookup
  -> duplicate transfer_out idempotency check
  -> DB::transaction
  -> sender/recipient wallet IDs by currency
  -> Wallet::whereIn(...)->orderBy('id')->lockForUpdate()
  -> sufficient balance check
  -> sender decrement, recipient increment
  -> create transfer_in and transfer_out rows
  -> return sender transfer_out TransactionResource
  -> invalidate walletProvider, walletsProvider, transactionHistoryProvider
  -> TransferResultScreen
```

Transfer uses deterministic ascending wallet-ID lock order to reduce deadlock risk.

## 12. Notifications, Fraud, Profile, Settings

Notifications: alert tab is local mock data from `mock_alert_notifications.dart`; transaction tab maps real transaction history into `AppNotification`. No backend notification route exists.

Fraud: `FraudAlertScreen` calls `FraudNotifier`, `FraudRepositoryImpl`, and `HttpFraudRemoteDataSource`, but the datasource returns hard-coded JSON after `Future.delayed`. Laravel has no fraud routes.

Profile: displays `authProvider.user`. Logout calls `AuthNotifier.logout()`, posts `/logout` best-effort, clears secure storage in `finally`, resets auth state, and navigates to login.

Settings: `SettingsNotifier` loads/saves `AppSettings` JSON through `SettingsRepositoryImpl` and `LocalStorageService`. No backend route or table exists.

## 13. Database Flow

Models:

- `User`: fillable `full_name`, `email`, `password`; hidden password/remember token; hashed password cast; `wallets()` has-many.
- `Wallet`: fillable `user_id`, `name`, `currency`, `balance`, `is_default`; decimal balance cast; `user()` and `transactions()` relationships.
- `Transaction`: fillable wallet/related/type/amount/balance/status/description/idempotency; decimal casts; `wallet()` and `relatedWallet()`.

Tables and constraints:

- `users.email` unique.
- `wallets.user_id` FK cascade delete.
- `wallets.balance >= 0`.
- `wallets.currency IN ('USD','KHR')`.
- unique `(wallets.user_id, wallets.currency)`.
- `transactions.wallet_id` FK cascade delete.
- `transactions.related_wallet_id` nullable FK null on delete.
- index `(transactions.wallet_id, transactions.created_at)`.
- transaction type/status/positive amount/nonnegative balance checks.
- unique `(transactions.idempotency_key, transactions.type)`.

## 14. Error Flow

Laravel validation failures return JSON `422`; Sanctum failures return `401`; throttling returns `429`; `firstOrFail()` returns `404`; business rule failures return `422` JSON or `ValidationException`; duplicate idempotency races catch MySQL code `1062` and return the existing transaction; unhandled API exceptions render JSON due to `bootstrap/app.php`.

Flutter maps Dio failures to `ApiException`. Bad responses extract only top-level `message`; field-level `errors` are not parsed. JSON parse failures such as unknown transaction type/status throw non-`ApiException` errors and usually surface as generic provider errors.

## 15. Testing and CI

Backend tests cover auth, wallet scoping, transaction history, top-up, transfer, idempotency, lock order, user search, and rate limiting. Frontend has only the default widget test discovered. Local `php artisan test` was started in the clone, produced no output for about 90 seconds, and was stopped; CI is configured to run tests against MySQL 8.0.

## 16. Documentation Index

- `docs/CODE_PROCESSING_FLOW.md`: this main report.
- `docs/FEATURE_EXECUTION_FLOWS.md`: feature-by-feature traces.
- `docs/LARAVEL_REQUEST_LIFECYCLE.md`: Laravel lifecycle detail.
- `docs/DATABASE_FLOW.md`: schema and database operation detail.
- `docs/ARCHITECTURE_AUDIT.md`: classified findings.
