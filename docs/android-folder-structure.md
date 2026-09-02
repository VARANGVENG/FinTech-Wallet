# NovaPay Android — Folder / Package Structure

This is a **proposal**, sized to this app's actual scope: 9 real features
(auth, dashboard, wallet, transactions, topup, transfer, notifications,
profile, settings — fraud is excluded, see `existing-system-analysis.md`
§11), each with 1–4 screens and one or two backend endpoints. The brief's
suggested `core/ + feature/` skeleton is used, but split across **two Gradle
modules** rather than one, for reasons explained in §1.

---

## 1. Two modules, not one

```
NovaPay-Android/
├── core-domain/     ← kotlin("jvm") — pure Kotlin, no Android/Compose
└── app/             ← com.android.application — Compose UI, Hilt, platform code
```

**`core-domain`** holds everything that is genuinely platform-independent:
network DTOs, the Retrofit API interfaces, the HTTP→`AppError` mapper, the
idempotency-key policy, and currency formatting. None of it imports
`android.*` or a Jetpack/Compose package. This is not a speculative
"future KMP" abstraction — it's drawn directly from what this app's riskiest
logic actually is (§5 of `android-architecture.md`), and it is the one part
of this repository that can be compiled and unit-tested with plain
`./gradlew :core-domain:test` in *any* environment, including this one,
where Google's Maven repository is not reachable (`android-architecture.md`
§4). A single-module app would still be correct; splitting it this way costs
one extra `build.gradle.kts` and buys a hard boundary against
"business logic accidentally imports `Context`."

**`app`** holds the Android application itself: Compose UI, ViewModels,
Hilt DI graph, Android platform integrations (Keystore-backed storage,
Navigation Compose, the manifest, resources).

---

## 2. Why Hilt (and why it isn't "unnecessary DI")

Nine features, each needing a `ViewModel` that depends on one or two
repositories, which depend on a shared `Retrofit`/`OkHttpClient`/token
store — that's a real, non-trivial object graph with real scoping needs
(the `OkHttpClient`/token store must be a true singleton; repositories are
one-per-feature singletons; ViewModels are screen-scoped). Hand-rolling this
with a manual `ServiceLocator` is more code, more places to get scoping
wrong, and doesn't integrate with `hiltViewModel()`'s automatic
`SavedStateHandle` support. Hilt is the standard, Google-recommended DI
solution for exactly this shape of app; it's used here because the object
graph actually warrants it, not by default.

---

## 3. `core-domain` (kotlin("jvm") module)

```
core-domain/src/main/kotlin/com/novapay/domain/
├── model/
│   ├── UserDto.kt              # id, full_name, email, is_verified
│   ├── WalletDto.kt            # id, name, currency, balance, is_default
│   ├── TransactionDto.kt       # + TransactionType, TransactionStatus enums
│   ├── PaymentMethodDto.kt
│   ├── PageMeta.kt             # current_page, last_page, per_page, total
│   └── requests/                # LoginRequest, RegisterRequest, TopUpRequest,
│                                  TransferRequest — one file per request body
├── api/
│   ├── AuthApi.kt               # Retrofit interface: register/login/me/logout
│   ├── WalletApi.kt             # wallets, wallets/default
│   ├── TransactionApi.kt        # wallets/default/transactions, wallets/{currency}/transactions
│   ├── TopUpApi.kt              # payment-methods, topups
│   └── TransferUserApi.kt       # users/search, transfers
├── error/
│   ├── AppError.kt              # sealed interface: Network, Timeout, Http(code,message,fieldErrors), Unknown
│   └── ErrorMapper.kt           # Throwable / Response<T> → AppError
├── idempotency/
│   └── IdempotencyKeyGenerator.kt   # wraps UUID.randomUUID().toString() behind an interface (fake-able in tests)
└── format/
    └── CurrencyFormatter.kt     # USD: 2dp, $; KHR: 0dp, ៛ — mirrors number_extensions.dart exactly
```

- **Depends on:** Kotlin stdlib, kotlinx.serialization, kotlinx.coroutines-core,
  Retrofit, OkHttp. All on Maven Central.
- **Depended on by:** every `feature/*` package in `app`, plus `app`'s
  `core/network` (which builds the concrete `Retrofit` instance implementing
  these interfaces).
- **Why it exists:** see `android-architecture.md` §4 — it is both good
  layering (business rules independent of platform) and the one thing
  provably unit-tested in a build environment where AndroidX is
  unreachable.
- **Why the API interfaces live here, not in `app`:** a Retrofit `interface`
  with `@GET`/`@POST` annotations has zero Android dependency — Retrofit and
  OkHttp are plain-JVM libraries. Keeping them next to the DTOs they return
  means a single source of truth for "what does the wire format look like,"
  testable with `MockWebServer` (also plain-JVM, Maven Central) without an
  emulator.

---

## 4. `app` (Android application module)

```
app/src/main/java/com/novapay/android/
├── NovaPayApp.kt                        # @HiltAndroidApp Application class
├── MainActivity.kt                       # single-activity host, sets Compose content
│
├── core/
│   ├── network/
│   │   ├── NetworkModule.kt              # Hilt: OkHttpClient, Retrofit, the 5 Api instances
│   │   ├── AuthInterceptor.kt            # attaches "Authorization: Bearer <token>"
│   │   └── BuildConfigUrls.kt            # base URL per build type (see api-integration.md §2)
│   ├── security/
│   │   ├── TokenStore.kt                 # EncryptedSharedPreferences-backed token read/write/clear
│   │   └── SecurityModule.kt             # Hilt bindings for TokenStore
│   ├── session/
│   │   └── SessionState.kt               # StateFlow<SessionState> — LoggedOut/Restoring/LoggedIn(user)
│   ├── navigation/
│   │   ├── NovaPayNavGraph.kt            # Navigation Compose graph, one composable() per screen
│   │   └── Destinations.kt               # sealed class of routes, incl. typed args (e.g. TransactionDetail(id))
│   ├── error/
│   │   └── ErrorPresentation.kt          # AppError → user-facing string (Compose-aware, uses resources)
│   ├── ui/
│   │   ├── theme/                         # Theme.kt, Color.kt (mirrors app/constants.dart AppColors), Type.kt
│   │   └── components/                    # PrimaryButton, DetailRow, ResultStatusHeader, SecureBadge,
│   │                                        AmountField, CurrencyPickerSheet, TransactionRow,
│   │                                        LoadingState/ErrorState/EmptyState composables,
│   │                                        NovaPayBottomBar
│   └── common/
│       └── UiText.kt                      # small helper: string-resource-or-literal wrapper for ViewModel→UI text
│
└── feature/
    ├── auth/
    │   ├── data/           AuthRepository, AuthRepositoryImpl (uses AuthApi + TokenStore)
    │   └── presentation/   SplashScreen, LoginScreen, RegisterScreen,
    │                        LoginViewModel, RegisterViewModel, SessionViewModel
    ├── dashboard/
    │   └── presentation/   HomeScreen, HomeViewModel (reads WalletRepository + TransactionRepository)
    ├── wallet/
    │   ├── data/           WalletRepository, WalletRepositoryImpl
    │   └── presentation/   WalletScreen, WalletViewModel
    ├── transactions/
    │   ├── data/           TransactionRepository, TransactionRepositoryImpl (owns pagination)
    │   └── presentation/   TransactionListSection (shared composable used by dashboard+wallet),
    │                        TransactionDetailScreen, TransactionListViewModel
    ├── topup/
    │   ├── data/           TopUpRepository, TopUpRepositoryImpl
    │   └── presentation/   TopUpScreen, ConfirmTopUpScreen, TopUpResultScreen, TopUpViewModel
    ├── transfer/
    │   ├── data/           TransferRepository, TransferRepositoryImpl
    │   └── presentation/   TransferScreen, RecipientPickerSheet, ConfirmTransferScreen,
    │                        TransferResultScreen, TransferViewModel
    ├── notifications/
    │   └── presentation/   NotificationsScreen, NotificationsViewModel (derives from TransactionRepository)
    ├── profile/
    │   └── presentation/   ProfileScreen, ProfileViewModel (reads AuthRepository)
    └── settings/
        ├── data/           SettingsRepository, SettingsRepositoryImpl (DataStore-backed, local only)
        └── presentation/   SettingsScreen, SettingsViewModel
```

### Package-by-package rationale

| Package | Responsibility | Depends on | Depended on by | Why it exists / why not elsewhere |
|---|---|---|---|---|
| `core/network` | Build the one shared `OkHttpClient`/`Retrofit`, attach the auth header, resolve the base URL per build type | `core-domain` (Api interfaces), `core/security` (token for the interceptor) | every `feature/*/data` | Same reason Flutter has exactly one `ApiClient` — one place owns timeouts, headers, base URL, so no feature datasource re-implements HTTP setup |
| `core/security` | Encrypted, Keystore-backed token storage; nothing else | AndroidX Security-Crypto | `core/network` (interceptor), `feature/auth/data` | Isolated so "how tokens are stored" has exactly one implementation, auditable in one file — see `security.md` |
| `core/session` | Holds *whether* the app currently has a valid session, as a `StateFlow`, for the nav graph to pick a start destination | `feature/auth/data` (constructor-injected `AuthRepository`) | `core/navigation`, `MainActivity` | The root composable needs "am I logged in" before it knows which graph to show — this tiny holder avoids the nav layer depending on a whole feature's ViewModels just to read one flag |
| `core/navigation` | One `NavHost`, one sealed-class route table | every `feature/*/presentation` screen composable | `MainActivity` | Centralizing routes means a screen never constructs a raw string route or reaches into another feature's internals to navigate to it — mirrors "navigation logic doesn't live in random composables" from the brief |
| `core/error` | Turn an `AppError` (from `core-domain`) into text/UI a screen can show | `core-domain` | every `feature/*/presentation` ViewModel | One error-presentation policy (§ `Part 12` mapping table lives in `api-integration.md`) instead of nine features each deciding how to phrase a 500 |
| `core/ui` | Design system: theme + the same handful of shared, cross-feature composables Flutter promotes into `shared/widgets/` once 2+ features need them | Compose, Material3 | every `feature/*/presentation` | Direct Android analogue of `lib/shared/widgets/` — promoted the same way Flutter's handoff doc describes: a widget moves here once a second feature needs it, not preemptively |
| `feature/auth` | Login, Register, Splash, session restore, logout | `core-domain`, `core/network`, `core/security` | `core/session`, `feature/profile` (reads current user + logout) | Owns the only two things that write/clear the token |
| `feature/dashboard` | Home tab: greeting, balance card (default wallet), quick actions, recent activity | `feature/wallet` (repo), `feature/transactions` (repo) | — | Thin composition feature, no repository of its own — same as Flutter's `HomeDashboardScreen`, which is pure UI over `walletProvider`/`transactionHistoryProvider` with no dashboard-specific data layer |
| `feature/wallet` | Wallet tab: USD/KHR list, currency switch, balance | `core-domain`, `core/network` | `feature/dashboard`, `feature/topup`, `feature/transfer` (all read wallet balance/currency) | Owns `WalletRepository` because wallet data is this feature's to own — others consume it through the repository interface, never re-fetch it themselves |
| `feature/transactions` | Transaction list (paginated) + detail screen, reused by both Dashboard and Wallet | `core-domain`, `core/network` | `feature/dashboard`, `feature/wallet`, `feature/notifications` | Same "one real API, one owner" rule as wallet; `TransactionListSection` is the shared composable both tabs render, exactly mirroring `BalanceOverviewScaffold` |
| `feature/topup` | 3-screen top-up flow + idempotency-key lifecycle | `core-domain`, `feature/wallet` (currency/balance context) | — | Self-contained write flow; nothing else needs to read top-up state |
| `feature/transfer` | Recipient lookup + 3-screen transfer flow + idempotency-key lifecycle | `core-domain`, `feature/wallet` | — | Same shape as top-up, kept separate because the request/validation/error surface is materially different (recipient lookup, self-transfer, insufficient balance) |
| `feature/notifications` | Transaction-derived notification tiles (see `existing-system-analysis.md` §10 — no real notifications endpoint exists) | `feature/transactions` (repo) | — | No repository of its own, by design — there is nothing to own; it's a view over transaction data, exactly like the Flutter reference's real half (the mock "Alerts" tab is intentionally not reproduced) |
| `feature/profile` | Read-only profile (from the session user) + Logout | `feature/auth` (repo) | — | No `/profile` endpoint distinct from `/me` exists — inventing a `ProfileRepository` around the same data `AuthRepository` already holds would be a pointless duplicate |
| `feature/settings` | 4 local-only preference toggles | `androidx.datastore` | — | Deliberately has no `core-domain`/network dependency at all — mirrors `SettingsRepositoryImpl` never touching `ApiClient` in the Flutter reference |

### Dependency direction rule

`core/*` never depends on `feature/*`. `feature/*` may depend on another
feature's `data` package (its repository interface) when it genuinely needs
that feature's data — e.g. `feature/dashboard` reading
`feature/wallet`'s `WalletRepository` — but never on another feature's
`presentation` package (a screen or ViewModel). This keeps the dependency
graph a DAG with `core-domain` and `core/*` at the bottom and `feature/*`
fanning out above it, the same shape the Flutter reference already has
(`domain → data → presentation`, features never importing another feature's
`presentation/` folder).
