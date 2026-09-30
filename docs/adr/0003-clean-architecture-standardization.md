# ADR 0003: Standardize the Flutter frontend on Clean Architecture, feature-first, no use-case layer

**Status:** Accepted

## Context

The original prototype had a dual state-management approach (mixing `provider`/`ChangeNotifier` with ad-hoc patterns) and no consistent structure across features. An early architecture audit rebuilt the app incrementally, feature by feature, and needed one consistent shape to rebuild into.

## Decision

Every feature under `lib/features/<name>/` follows the same layering:
```
domain/repositories/     — abstract repository interface
data/model/               — plain Dart data classes
data/datasource/          — concrete datasource (HTTP-backed)
data/repositories/        — concrete repository implementing the domain interface
presentation/provider/    — Riverpod StateNotifier + StateNotifierProvider
presentation/screen/      — full-page widgets
presentation/widget/      — feature-local reusable widgets
```
State management is Riverpod `StateNotifier`/`StateNotifierProvider` exclusively — no `ChangeNotifier`/`provider` package anywhere. Widgets used by 2+ features are promoted to `lib/shared/widgets/`.

**Deliberately no use-case layer.** A provider/notifier calls its repository directly; there is no intermediate "use case" class between them anywhere in the app. This was reaffirmed explicitly during NOV-16 (building the biometrics feature's domain/repository layer): the original Biometric Audit's plan called for a use-case layer there, but since every other feature — Auth, Wallet, Transfer, Top-up — already calls its repository directly with no such indirection, adding one only for biometrics would have introduced a one-off pattern inconsistent with the rest of the codebase, for a class of logic (pure delegation, no orchestration across multiple repositories) that doesn't need it.

## Consequences

**Positive:** every layer is independently testable — this is directly evidenced by the test suites written across this project (repository-impl tests mocking the datasource, provider tests mocking the repository, e.g. `frontend/test/features/*/data/repositories/*_test.dart` and `frontend/test/features/*/presentation/providers/*_test.dart`). The mock-repository pattern used during initial development (each datasource commented out its real HTTP call directly above a mock return) made the eventual mock-to-real-HTTP swap mechanical rather than a rewrite.

**Accepted trade-off:** skipping the use-case layer means any future feature whose logic genuinely spans multiple repositories (rather than one provider talking to one repository) will need a deliberate decision about where that orchestration lives — there is no established pattern for it yet, because no feature so far has needed one.

**Naming note:** `presentation/screen/` (not `page`/`pages`) was chosen specifically to avoid a future collision with `go_router`'s own `Page` type, in case that currently-unused dependency (`go_router` is declared in `pubspec.yaml` with zero imports anywhere in `lib/`) is ever actually adopted.
