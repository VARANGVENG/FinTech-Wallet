# NovaPay Android — Implementation Roadmap

Each phase: inspect (done, `existing-system-analysis.md`) → design (this
document + the flow docs) → implement → test → explain → document, per
Part 20 of the brief. Phases are committed incrementally to the `develop`
branch as they complete.

| # | Phase | Goal | Key files/components | Depends on | Expected result | Tests |
|---|---|---|---|---|---|---|
| 1 | Project bootstrap | `settings.gradle.kts` wiring `core-domain` + `app`; version catalog (`libs.versions.toml`) with the exact versions from `android-architecture.md` §2 | `settings.gradle.kts`, `gradle/libs.versions.toml`, both modules' `build.gradle.kts`, `gradle.properties` | — | `./gradlew :core-domain:help` succeeds in this sandbox (proves the JVM module's Gradle config is valid); `:app` requires a normal-internet machine (`testing-plan.md` §1) | — |
| 2 | `core-domain`: models + API interfaces | DTOs matching the exact API contract (`existing-system-analysis.md` §4), Retrofit interfaces | `model/*.kt`, `api/*.kt` | 1 | Serialization round-trips a fixture JSON for every endpoint | `*DtoSerializationTest` per model |
| 3 | `core-domain`: error mapping + idempotency + currency formatting | `AppError`, `ErrorMapper`, `IdempotencyKeyGenerator`, `CurrencyFormatter` | `error/*.kt`, `idempotency/*.kt`, `format/*.kt` | 2 | Every case in `api-integration.md` §4's table has a passing test; `CurrencyFormatterTest` matches `number_extensions.dart`'s exact output for a table of sample values | `ErrorMapperTest`, `CurrencyFormatterTest` |
| 4 | `app` bootstrap: manifest, theme, Hilt | `NovaPayApp`, `MainActivity`, `core/ui/theme/*`, network security config, backup rules | `AndroidManifest.xml`, `NovaPayApp.kt`, `MainActivity.kt`, theme files | 1 | Structurally complete Android module (requires local build to compile — §`testing-plan.md` §1) | — |
| 5 | `core/network` + `core/security` | `NetworkModule` (OkHttp/Retrofit), `AuthInterceptor`, `TokenStore` (EncryptedSharedPreferences) | `core/network/*.kt`, `core/security/*.kt` | 3, 4 | Wired per `api-integration.md`, `security.md` §2 | `TokenStoreTest` (Robolectric or instrumented — deferred to local run) |
| 6 | `core/navigation` + `core/session` | `NovaPayNavGraph`, `Destinations`, `SessionState` | `core/navigation/*.kt`, `core/session/*.kt` | 5 | Nav graph compiles with placeholder screens for every destination | — |
| 7 | `feature/auth` | Splash, Login, Register, session restore, logout | `feature/auth/**` | 5, 6 | Matches `authentication-flow.md` exactly, including the 401→Login fix (`api-integration.md` §3) | `LoginViewModelTest`, `RegisterViewModelTest`, `AuthRepositoryTest` |
| 8 | `feature/wallet` | Wallet tab, currency picker | `feature/wallet/**` | 7 | Matches `wallet-flow.md` | `WalletViewModelTest`, `WalletRepositoryTest` |
| 9 | `feature/transactions` | Paginated list (shared by Dashboard/Wallet) + detail screen | `feature/transactions/**` | 8 | Real pagination, unlike the Flutter reference (`existing-system-analysis.md` §2.5, §7) | `TransactionListViewModelTest` (incl. a paging-source test) |
| 10 | `feature/dashboard` | Home tab composing wallet + transactions | `feature/dashboard/**` | 8, 9 | Matches `existing-system-analysis.md` §12's compatibility row for Dashboard | `HomeViewModelTest` |
| 11 | `feature/topup` | 3-screen flow, idempotency, fixed `isSubmitting` bug | `feature/topup/**` | 8 | Matches `topup-flow.md` exactly | Full matrix in `testing-plan.md` §4 |
| 12 | `feature/transfer` | Recipient lookup + 3-screen flow, idempotency | `feature/transfer/**` | 8, 9 | Matches `transfer-flow.md` exactly | Full matrix in `testing-plan.md` §5 |
| 13 | `feature/notifications` | Transaction-derived tab only (no mock alerts — `existing-system-analysis.md` §10) | `feature/notifications/**` | 9 | — | `NotificationsViewModelTest` |
| 14 | `feature/profile` + `feature/settings` | Read-only profile + logout; local DataStore preferences | `feature/profile/**`, `feature/settings/**` | 7 | — | `SettingsRepositoryTest` |
| 15 | Wire `NovaPayNavGraph` fully, bottom nav, `FLAG_SECURE` on sensitive screens | Replace placeholders from phase 6 with real screens; apply `security.md` §8 | `core/navigation/**` | 7–14 | Full app navigable end-to-end (verified on a local machine/emulator — §`testing-plan.md` §1) | Manual golden-path walkthrough |
| 16 | Testing pass | Fill any gaps against `testing-plan.md`'s matrices; run `core-domain` tests in this session | all | 1–15 | `core-domain` test output shown in this session; `app` test/coverage summary documented as "to run locally" | Full suite |
| 17 | Final review + documentation | `Novapay-Android-Architecture.md`/`.pdf` describing what was **actually built**, not the plan | `docs/**` | 1–16 | Diagrams match the real final structure; verification checklist completed honestly (`testing-plan.md` §1 distinctions preserved) | — |

---

## Notes on sequencing

- **`core-domain` (phases 1–3) is built and tested first, standalone**,
  precisely because it's the one thing provably verifiable in this
  environment (`testing-plan.md` §1) — every later phase's tests for `app`
  code depend on these types already existing and being correct.
- **Auth (7) before every feature**, since every other endpoint requires a
  bearer token and every screen's nav destination depends on `SessionState`.
- **Wallet (8) before Transactions/Top-up/Transfer/Dashboard**, since all
  four read wallet data or currency context.
- **Notifications (13) depends only on Transactions**, not on Top-up/Transfer
  — it renders existing transaction data, it doesn't need the write flows to
  exist first.
- No phase modifies `backend/` or `frontend/` — every change in this roadmap
  is additive, under a new top-level Android project directory, per the
  brief's "do not rewrite working backend code" / "do not modify Laravel
  business rules" / "do not modify Flutter" instructions.
