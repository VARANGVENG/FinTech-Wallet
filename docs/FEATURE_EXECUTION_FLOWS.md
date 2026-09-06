# Feature Execution Flows

## Registration

`RegisterScreen` calls `AuthNotifier.register()`. The notifier sets `AuthStatus.loading`, calls `AuthRepositoryImpl.register()`, which calls `AuthRemoteDataSource.register()`, which sends `POST /register` through `ApiClient`.

Laravel route `backend/routes/api.php` maps `POST /api/v1/register` to `AuthController::register()` with `guest` and `throttle:register`. `RegisterRequest` requires `full_name`, unique email, and confirmed min-8 password. The controller uses `DB::transaction()` to create the user, default USD wallet, and KHR wallet. After commit it creates a Sanctum token and returns `{user, token, token_type}` with HTTP 201.

## Login and Current User

`LoginScreen` calls `AuthNotifier.login()`, then `AuthRepositoryImpl.login()`, `AuthRemoteDataSource.login()`, and `ApiClient.post(ApiEndpoints.login)`. Laravel validates `LoginRequest`, fetches `User::where('email')`, checks `Hash::check()`, creates a Sanctum token, and returns a `UserResource` plus token. Bad credentials return 401 with a generic message.

`_StartupGate` in `main.dart` restores sessions by checking secure token presence, calling `AuthNotifier.restoreSession()`, and hitting `GET /me`. `AuthController::me()` returns the authenticated user resource. On a confirmed 401, `AuthInterceptor` clears the token.

## Wallets and Balances

`HomeDashboardScreen`, `WalletScreen`, and `BalanceOverviewScaffold` read `walletProvider` or `walletsProvider`. Those providers require `authProvider.user`, then call `WalletRepositoryImpl`, `WalletRemoteDataSource`, and `GET /wallets/default` or `GET /wallets`.

Laravel `WalletController::default()` and `index()` query `$request->user()->wallets()`, so wallet access is scoped to the authenticated user. Output is transformed by `WalletResource` and parsed by `WalletModel.fromJson()`.

## Transaction History

`BalanceOverviewScaffold` watches `transactionHistoryProvider` for default-wallet history or `walletTransactionsProvider(currency)` for selected wallet history. The repository calls `TransactionRemoteDataSource`, which sends `GET /wallets/default/transactions` or `GET /wallets/{currency}/transactions`.

Laravel `TransactionController` resolves the authenticated user's default or currency wallet, calls `$wallet->transactions()->latest()->paginate(20)`, and returns `TransactionResource` collection plus pagination `meta`. Flutter parses the list into `TransactionModel` and displays `CustomTransactionHistoryItem`; tapping opens `TransactionDetailScreen`.

## Top-up

`TopUpScreen.initState()` calls `TopUpNotifier.loadPaymentMethods()`, which goes through `TopUpRepositoryImpl` and `TopUpRemoteDataSource` to `GET /payment-methods`. `TopUpController::methods()` returns a fixed in-controller list; there is no payment-method table.

On confirmation, `ConfirmTopUpScreen._handleConfirm()` calls `TopUpNotifier.submit()`. The POST body is `{amount, currency, method, idempotency_key}`. Laravel validates with `StoreTopUpRequest`, checks for an existing transaction by idempotency key, locks the user's wallet for the currency, increments `balance`, creates a `topup` transaction with `balance_after`, and returns `TransactionResource`. Duplicate-key races catch MySQL 1062 and return the existing transaction.

## Transfer

Recipient selection starts in `RecipientPickerSheet._search()`. It calls `TransferRepositoryImpl.findRecipient()`, `TransferRemoteDataSource.findRecipient()`, and `GET /users/search?email=...`. `UserController::search()` validates the query email and returns a `UserResource` or 404.

On confirmation, `ConfirmTransferScreen._handleConfirm()` calls `TransferNotifier.submit()`. The POST body is `{recipient_email, amount, currency, idempotency_key, note?}`. Laravel validates with `StoreTransferRequest`, rejects self-transfer, resolves recipient, checks existing `transfer_out` by idempotency key, then starts `DB::transaction()`. It finds both wallet IDs for the selected currency, locks both wallets using `orderBy('id')->lockForUpdate()`, checks sufficient balance, decrements sender, increments recipient, creates `transfer_in` and `transfer_out` rows, and returns the sender transaction resource.

## Notifications

Alert notifications come from `mock_alert_notifications.dart` and are held in `NotificationsNotifier`. `NotificationsScreen.initState()` marks them all read. Transaction notifications come from `transactionNotificationsProvider`, which maps real transaction history into `AppNotification.fromTransaction()`.

## Fraud Alerts

Fraud UI is simulated. `FraudAlertScreen` calls `FraudNotifier`, which calls `FraudRepositoryImpl`, which calls `HttpFraudRemoteDataSource`. That datasource returns hard-coded data after `Future.delayed()`. No Laravel fraud route/controller/model/migration exists.

## Profile and Settings

`ProfileScreen` displays `authProvider.user`. Logout calls `AuthNotifier.logout()`, posts `/logout` best-effort, clears secure storage, resets auth state, and navigates to login.

`SettingsScreen` calls `SettingsNotifier.loadSettings()` once. Settings are `AppSettings` JSON stored through `SettingsRepositoryImpl` and `LocalStorageService`. No backend route exists.
