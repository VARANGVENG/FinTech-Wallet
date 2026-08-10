# NovaPay (fintech_wallet) — Session Handoff

**Branch:** `feature/topup`
**Last updated:** 2026-08-07
**Collaboration mode:** Strict mentor mode (see Section 11 — read this before doing anything else)

---

## 1. Project Overview

NovaPay is a Flutter fintech wallet mobile app (package name `fintech_wallet`). It is currently a **frontend-only prototype** — every feature is backed by a mock repository (`Future.delayed` + hardcoded data), not a real API. A companion document, [`novapay-backend-plan.md`](novapay-backend-plan.md), describes a planned Laravel + Sanctum backend (schema + endpoints + phased build order) that does **not exist yet** as actual backend code — it's a spec only.

**Stack**
- Flutter SDK `^3.11.5`, Flutter engine 3.41.9 installed locally
- **State management:** `flutter_riverpod ^2.6.1` — `StateNotifier`/`StateNotifierProvider` used uniformly across the entire app. This was a deliberate standardization (see Section 4); no other state approach should be introduced.
- **HTTP:** `dio ^5.9.0` — `ApiClient`/`AuthInterceptor`/`ApiEndpoints` exist in `lib/core/network/` but are **not wired to any real backend yet**. No feature actually issues a live HTTP call.
- **Storage:** `flutter_secure_storage` (`SecureStorageService`, for auth tokens — wired into `AuthInterceptor` but never actually populated, since login never persists a token) and `shared_preferences` (`LocalStorageService`, genuinely used by Settings for real local persistence).
- **Other deps present but unused:** `go_router ^16.0.0` (declared in `pubspec.yaml`, zero imports anywhere in `lib/` — navigation is 100% `Navigator.push`/`MaterialPageRoute`), `local_auth ^2.3.0` (declared, unused — Biometric Login toggle in Settings has no real biometric prompt behind it), `freezed_annotation`/`json_annotation` (declared, unused — no models use them).

**Architecture:** Clean Architecture, feature-first. Every feature under `lib/features/<name>/` follows:
```
domain/repositories/     — abstract repository interface
data/model/               — plain Dart data classes
data/datasource/          — abstract + Http* mock implementation (commented-out real HTTP calls)
data/repositories/        — concrete repository implementing the domain interface
presentation/provider/    — StateNotifier + StateNotifierProvider
presentation/screen/      — full-page widgets (NOT "page" — see naming note below)
presentation/widget/      — feature-local reusable widgets
```
Widgets used by 2+ features live in `lib/shared/widgets/`. Cross-cutting utilities live in `lib/shared/utils/`.

**Naming convention:** `presentation/screen/` (not `page`/`pages`), chosen specifically so it won't collide with `go_router`'s own `Page` type once/if `go_router` is actually adopted.

---

## 2. Current Progress

Everything below is **built and functional** against mock data unless noted otherwise.

| Feature | State | Notes |
|---|---|---|
| **Auth** | Login, Register, Splash | `AuthRepository` real interface, but `AuthRemoteDataSource` is hardcoded mock credentials. No token persistence. Logged-in `User` stored in `AuthState.user`. |
| **Navigation** | Done | `PageView` + `PageController` (swipeable), dense 0–3 tab indices (Home/Wallet/Transfer/Profile), `AutomaticKeepAliveClientMixin` preserves each tab's scroll/form state across swipes. Center "+" nav button is decorative only (`TODO` at `lib/app/main_navigation.dart:96`). |
| **Dashboard / Wallet** | Done | Share `BalanceOverviewScaffold` (header, bell w/ unread badge, balance card slot, quick actions slot, transaction list). Transaction list is a static shared mock (`lib/core/mock/mock_transaction_history.dart`). |
| **Top-up** | Done (3 screens) | TopUpScreen → ConfirmTopUpScreen → TopUpResultScreen. Manual amount entry works (real `TextField`, not chip-only). |
| **Transfer** | Done (3 screens), **major redesign not yet committed** | TransferScreen → ConfirmTransferScreen → TransferResultScreen. Recipient picker is now a searchable `DraggableScrollableSheet` (not a fixed default contact). Source wallet is selectable from a real list (2 mock wallets) instead of hardcoded balance. See Section 8 — this redesign is sitting as uncommitted changes. |
| **Profile** | Done | Real logged-in user (avatar initials, name, email), working logout (`authProvider.notifier.reset()` + `pushAndRemoveUntil` to Login). Menu rows are separate `Container` cards with icons; no "Settings" row by design (Settings reached via Dashboard header tap). |
| **Settings** | Done | Real persistence via `LocalStorageService`/`shared_preferences` (not mocked — genuinely local, no backend endpoint planned). Toggles: Push Notifications, Transaction Alerts, Biometric Login (no real biometric behind it yet), Dark Mode (no real theming behind it yet). |
| **Notifications** | Done | Alerts/Transactions tabs, unread-count badge on bell (derived `Provider<int>`, not a getter — see Section 4), tap-through to `TransactionDetailScreen` or `FraudAlertScreen`. |
| **Transaction Detail** | Done | Shared screen, opened from Dashboard/Wallet lists and from Notifications. "Report an Issue" button is a stub (`TODO`). |
| **Fraud Alert** | Done | Reached only via one specific mock notification ("Suspicious Transaction Detected"). Dispute flow ("This wasn't me" / "It was me") is mocked, no real backend call. |
| **Withdraw** | **Not started** | No feature folder exists. |
| **Profile sub-pages** | **Not started** | Personal Information, Security, Linked Accounts, Documents, Support Center rows in Profile all navigate nowhere real yet (or are stubs). |

CI: `.github/workflows/analyze.yml` runs `flutter analyze` on push to `main`/`develop`/`feature/topup` via `subosito/flutter-action@v2` pinned to `3.41.9`. Classic branch protection is configured but **not enforced** (GitHub free-tier limitation on private repos) — user explicitly accepted this as-is.

`flutter analyze` currently reports **zero issues**.

---

## 3. Current Feature

No feature is mid-build right now — the session ended at a **planning checkpoint**, not inside a file. The last substantive discussion was:

1. A full comparison of the app against `novapay-backend-plan.md` (see Section 8 for the gap summary).
2. A direct question from the user: given they want a "first version" of the app with **real backend integration**, aimed at demonstrating to an internship/junior-role reviewer (not expected to be feature-complete), what should the v1 scope be?
3. My recommendation (**not yet confirmed by the user** — this is the open question to resolve first next session):
   1. Real Auth (Register + Login + token persistence)
   2. Real Wallet balance + Transaction History (read path)
   3. Top-up (first write path — simplest to convert)
   4. Transfer (second write path — most demo-impressive, fintech-specific)
   - Explicitly **excluding** Fraud Alert, Notifications, and Settings from v1 (they stay mock/local).
   - This order matches `novapay-backend-plan.md`'s own phased build order.

The user had not yet responded to this recommendation when the session ended.

---

## 4. Decisions Already Made

These are settled; don't relitigate them without a fresh, explicit ask from the user.

- **Riverpod `StateNotifier` only**, no `ChangeNotifier`/`provider` package. Chosen early (audit Task 5) to resolve a dual-state-management inconsistency found in the original code.
- **Clean Architecture, feature-first**, domain/data/presentation split per feature — chosen for testability and to make the eventual mock→real-HTTP swap mechanical (see below).
- **Mock repository pattern**: every datasource is `Http<Feature>RemoteDataSource` with `Future.delayed(...)` + hardcoded data, and the real HTTP call is written out **as a comment directly above** the mock return, ready to uncomment. This is deliberate and consistent across every feature — preserve it when doing real backend integration (uncomment + wire, don't rewrite from scratch).
- **`presentation/screen/` naming**, not `page`/`pages` — reserved to avoid a future collision with `go_router`'s `Page` type.
- **Shared widget promotion rule**: a widget gets moved from a feature's `presentation/widget/` into `lib/shared/widgets/` once a second feature needs it (e.g. `PrimaryButton`, `MenuTile`, `DetailRow`, `ResultStatusHeader`, `SecureBadge`).
- **Settings uses `LocalStorageService` directly**, no datasource/mock-HTTP layer — deliberate, because these are genuinely local device preferences with no planned backend endpoint, unlike every other feature's data.
- **Avatar colors are computed client-side** (`AvatarColor` extension, hash → palette lookup) rather than treated as backend data — purely presentational, not real user data.
- **`FlaggedTransaction` is a separate model**, not a variant of `TransactionHistoryModel` — the Fraud Alert mockup's example data didn't correspond to any real mock transaction, so forcing a shared model would have been artificial.
- **`PageView` + `AutomaticKeepAliveClientMixin`** for main nav (not `IndexedStack`) — enables swipe gestures between tabs while preserving each tab's scroll position/form state. Applied to Home/Wallet/Transfer (stateful, has scroll/form state) but not Profile (stateless `ConsumerWidget`, nothing to preserve).
- **`constants.dart` stays as the original, simpler `AppColors`-only file.** A migration to a richer design-system file (`AppSpacing`/`AppRadius`/`AppShadows`/`AppDurations`/`AppConstants`, plus a renamed `AppColors.surface`) was attempted and **explicitly reverted** by the user because it broke text/icon colors across ~8 files (the new `surface` meant "dark card background," the old meant "white foreground text/icon color" — direct role collision). **Do not re-attempt this migration without a fresh, explicit user decision**, and if revisited, the fix is to rename usages to something like `textOnPrimary` rather than reusing `surface`.
- **Derived `Provider<int>` for unread notification count** (`unreadNotificationCountProvider`), not a getter on `NotificationsNotifier` — reading `ref.watch(someProvider.notifier)` does not react to internal state changes in Riverpod; a derived `Provider` watching the state provider is the correct reactive pattern. Apply this same pattern anywhere else a "computed value from a StateNotifier's state" is needed.
- **Transfer has no `getDefaultRecipient()`** — removed entirely when the recipient picker was built; recipient is always explicitly chosen via `RecipientPickerSheet`.
- **Recipient picker is a `showModalBottomSheet` (`DraggableScrollableSheet`), not a full `Navigator.push` screen** — matches the mockup's overlay-on-top-of-Transfer behavior, bottom nav visible underneath.

---

## 5. Remaining Tasks

**High priority (v1 backend integration, pending user confirmation of scope — see Section 3):**
- [ ] Confirm v1 scope with user (Auth → Wallet/Transactions → Top-up → Transfer, per my recommendation)
- [ ] Stand up the actual Laravel backend per `novapay-backend-plan.md` (currently spec-only, no backend repo/code exists)
- [ ] Wire real Auth: `AuthRemoteDataSource` real HTTP calls, remove hardcoded mock credentials, persist token via `SecureStorageService` (currently never written to)
- [ ] Extend `TransactionHistoryModel` — missing `type`, `category`, `reference`, `payment_method`, `flagged` fields, and only 2 of the plan's 4 transaction statuses exist (`pending`/`completed`; missing `failed`/`on_hold`) — this is the single biggest structural gap versus the backend plan
- [ ] Wire real Wallet balance + Transaction History read endpoints
- [ ] Wire real Top-up write endpoint
- [ ] Wire real Transfer write endpoint

**Medium priority:**
- [ ] Withdraw feature (not started at all)
- [ ] Profile sub-pages: Personal Information, Security, Linked Accounts, Documents, Support Center (currently non-functional rows)
- [ ] Decide fate of `go_router` dependency — either adopt it for real or remove the unused dependency

**Low priority / polish:**
- [ ] Wire the center "+" nav button (`lib/app/main_navigation.dart:96`)
- [ ] Transaction Detail "Report an Issue" button (stub)
- [ ] Top-up/Transfer Result screens' "view receipt" navigation (both `TODO`, currently dead-end)
- [ ] Real biometric prompt behind Settings' Biometric Login toggle (`local_auth` is declared but unused)
- [ ] Real theming behind Settings' Dark Mode toggle (currently cosmetic-only)
- [ ] Change PIN / Change Password / Two-Factor Authentication rows in Settings (currently decorative)
- [ ] `test/widget_test.dart` is still the unmodified Flutter counter-app template — will fail if `flutter test` is ever run. Flagged early in the project, never fixed.
- [ ] `.vscode/` line in `.gitignore` — currently commented out (`#.vscode/` was the old state; verify current — see Section 8), flagged multiple times, never actioned by the user.

---

## 6. Next Session Plan

1. **Re-check `git status`** before doing anything else — there are substantial uncommitted changes right now (see Section 8). Don't assume the last session's commit-grouping recommendations were actually applied.
2. Get the user's explicit confirmation/adjustment on the v1 backend-integration scope (Section 3).
3. Once confirmed, follow mentor-mode process per feature, in order:
   - Analyze current mock implementation → confirm what the real endpoint contract looks like (cross-check `novapay-backend-plan.md`) → design the swap → implement one file at a time → `flutter analyze` → user manual test → commit recommendation.
4. Suggested concrete order once scope is confirmed: Auth token persistence first (unlocks everything else being able to make authenticated calls), then Wallet/Transactions (read-only, lowest risk), then Top-up, then Transfer.
5. Backend itself: the Laravel project doesn't exist yet in this repo — clarify with the user whether it's being built in this same repo, a separate repo, or is someone else's responsibility, since that materially changes what "next session" should actually do.

---

## 7. Important Files

| File | Purpose |
|---|---|
| `lib/main.dart` | App entrypoint, async `main()`, wraps app in `ProviderScope` |
| `lib/core/providers/core_providers.dart` | Root Riverpod providers (API client, storage services, auth interceptor wiring) |
| `lib/core/network/api_client.dart`, `api_endpoints.dart`, `auth_interceptor.dart` | `dio`-based HTTP layer — built but not yet called by any real feature |
| `lib/core/storage/secure_storage_service.dart` | Auth token storage — wired into `AuthInterceptor` but never populated (no real login writes a token yet) |
| `lib/core/storage/local_storage_service.dart` | `shared_preferences` wrapper — actually used by Settings |
| `lib/core/mock/mock_transaction_history.dart` | Shared mock transaction list used by Dashboard, Wallet, and Notifications |
| `lib/app/constants.dart` | `AppColors` — **do not migrate to a richer design system without fresh approval** (see Section 4) |
| `lib/app/main_navigation.dart` | `PageView`-based bottom-nav shell, dense 0–3 indexing |
| `lib/app/router.dart`, `app.dart`, `environment.dart` | **Empty files (0 bytes), currently unused** — `go_router` was never actually adopted |
| `lib/shared/widgets/balance_overview_scaffold.dart` | Shared Dashboard/Wallet page shell |
| `lib/shared/widgets/menu_tile.dart` | Shared menu row widget (Profile, Settings) |
| `lib/features/transfer/` | Most recently and extensively redesigned feature — recipient picker, multi-wallet source selection. **Currently has uncommitted changes** (Section 8). |
| `lib/features/dashboard/presentation/model/transaction_history_model.dart` | Core transaction model — flagged as needing extra fields to match backend plan (Section 5) |
| `novapay-backend-plan.md` | Laravel/Sanctum backend spec (schema + endpoints + phased build order) — spec only, no backend code exists |
| `.github/workflows/analyze.yml` | CI: `flutter analyze` on push to `main`/`develop`/`feature/topup` |

---

## 8. Open Issues

- **Uncommitted working tree changes right now** — the last session's Transfer redesign, Profile/Settings icon work, and divider fix were reportedly tested ("app running fine") but **were never verified as actually committed**. Current `git status --short` shows modifications across `profile_screen.dart`, `settings_screen.dart`, `settings_switch_tile.dart`, `topup_screen.dart`, all of `features/transfer/`, `string_extensions.dart`, `balance_overview_scaffold.dart`, `detail_row.dart`, `menu_tile.dart`, plus two untracked new files (`features/transfer/data/model/wallet.dart`, `features/transfer/presentation/widget/recipient_select_prompt.dart`). **Re-verify and commit these properly before starting new work.**
- No auth token persistence — `SecureStorageService` exists and is wired into `AuthInterceptor`, but nothing ever calls `setAuthToken` because login is still fully mocked.
- `TransactionHistoryModel` is missing `type`, `category`, `reference`, `payment_method`, `flagged`, and 2 of 4 planned status values (`failed`, `on_hold`) versus `novapay-backend-plan.md`.
- `lib/app/router.dart`, `app.dart`, `environment.dart` are all empty (0 bytes) — dead files. `go_router` is a declared dependency with zero actual usage anywhere in `lib/`.
- Six `TODO` markers remain unresolved: center "+" nav button, both Login/Register "Call API here" stubs, Top-up/Transfer Result screens' receipt navigation, Transaction Detail's dispute-reporting button.
- `test/widget_test.dart` is still the default Flutter counter-app template — unrelated to this app, will fail if run.
- Biometric Login and Dark Mode toggles in Settings persist a value but don't actually change app behavior (no real `local_auth` prompt, no real theme switch).
- Branch protection on GitHub is configured but not enforced (private repo, free tier) — accepted as-is by the user, not a bug to fix, just a known limitation.

---

## 9. Things NOT to Change

- **Do not reintroduce `provider`/`ChangeNotifier`** anywhere — Riverpod `StateNotifier` is the sole, deliberate standard.
- **Do not migrate `lib/app/constants.dart`** to the richer design-system version without fresh, explicit user approval — it was tried once and explicitly reverted for breaking text/icon colors app-wide.
- **Do not rename `presentation/screen/` back to `page`/`pages`** — reserved naming to avoid a future `go_router` `Page` collision.
- **Do not remove the mock-repository pattern's commented-out real-HTTP-call blocks** — they are the intended guide for backend integration; uncomment and adapt them rather than rewriting from scratch.
- **Do not remove the Transfer tab from the bottom nav** — this was tried once mid-session and explicitly reverted by the user ("don't change the navigation bar just continue the old").
- **Do not collapse `unreadNotificationCountProvider` into a getter on `NotificationsNotifier`** — it must stay a separate derived `Provider` to remain reactive (Riverpod anti-pattern, see Section 4).
- **Do not remove or restructure `BalanceOverviewScaffold`** without checking both Dashboard and Wallet still work — it's shared by both and was previously found accidentally unwired (screens still had 150 lines of duplicated old code) during a lint cleanup pass.

---

## 10. Context for the Next AI

This project started as a genuinely broken prototype (compile errors, dual state management, ~18% complete per the original audit) and has been rebuilt incrementally, one file at a time, under strict mentor-mode rules (Section 11) over a long session. Every feature currently in the app (Section 2) was built from scratch or substantially reworked during that process — there is no legacy code left that predates this collaboration except the original mock data shapes and the backend plan document.

The user is working toward a demo-able "v1" for an internship/junior-role reviewer, not a fully-complete production app — scope discipline matters more than feature breadth here. When in doubt about whether something belongs in v1, default to "no" and flag it as a later-phase item instead, consistent with the phased approach `novapay-backend-plan.md` itself lays out.

A recurring failure mode across the session was **trusting stale assumptions about file content** — several times, code I described as "already applied" turned out to be partially applied, applied to the wrong path, or reverted by the user without saying so. **Always re-`Read` the actual current file before writing a diff or explaining "how it currently works,"** even if you (or the prior session) believe you already know its contents. This handoff document itself was fact-checked against the live repo (file tree, git log, `flutter analyze`, key file contents) rather than written from memory alone — do the same for anything load-bearing before acting on it.

The user has repeatedly caught real bugs via manual testing and screenshots (tripled chevron icon, non-editable amount field, misplaced/misimported Fraud Alert screen) that `flutter analyze` did not catch — treat `flutter analyze` passing as necessary, not sufficient; the user's own runtime testing is still the real verification step, and you should keep asking them to do it rather than declaring a feature done on static analysis alone.

---

## 11. Development Rules

These are the user's explicit, durable collaboration rules for this project. They apply to every future session until the user changes them.

1. **Role:** Act as a Senior Software Engineer / Architect / Tech Lead and **mentor** — not an autonomous implementer.
2. **Never auto-apply file changes.** Do not use `Write`/`Edit` to create, modify, rename, move, or delete files without the user pasting the code in themselves. Do not run terminal commands that mutate repo state (`commit`, `push`, `merge`, branch operations, `git add`). Read-only exploration (`Read`, `Grep`, `Glob`, `Bash` for `flutter analyze`/`git status`/`git log`) is fine and expected.
3. **When code is needed:** state the exact file path, say whether it's new or existing, explain why it belongs there, generate **one file at a time**, and give the user the code to paste in themselves.
4. **Git:** recommend commands with an explanation; the user runs them.
5. **Work order:** one task at a time from an approved priority list. Note other discovered issues but don't act on them without explicit approval.
6. **Before writing code:** analyze the current implementation → explain the problem/why it matters → describe the expected behavior → recommend a solution with trade-offs → wait if more information is needed.
7. **After writing code:** explain the execution flow, the purpose of each class/method, and how the files interact.
8. **Flag inconsistencies explicitly** (architecture, naming, state-management) rather than silently introducing a new pattern to work around them.
9. **Break work into small milestones** (analyze → design → implement one file → test → explain) with an approval gate between each.
