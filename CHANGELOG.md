# Changelog

Notes for each build pushed to `production`. The top entry is what
Firebase App Distribution shows testers for the current release.

## v0.2.0+2

- Fixed a typo in the Drift schema: `occuredTime` → `occurredTime` (column
  and field), caught before any real user data existed so no migration was
  needed.
- Added mocktail-based unit tests for `TransactionsBloc` and
  `BalanceCubit`, covering failure paths a real repository couldn't be
  forced into.
- Fixed a silent bug where a repository stream error during app launch
  produced an uncaught async error instead of a `TransactionsError` state.
- Set up the `production` deploy pipeline: signed release builds now go
  out to Firebase App Distribution automatically, with real per-release
  notes pulled from this file.
- Added a "Download APK" badge to the README linking to the latest GitHub
  release, so visitors can actually install the app instead of just
  reading about it.

## v0.2.0 — Themed redesign

- Introduced a dedicated design system (`AppColors` + `AppTheme`) with
  light and dark color tokens — dark-first, following the system theme by
  default — replacing the single generic Material seed color.
- Split the 350+ line `transactions_screen.dart` into small, single-purpose
  widgets (`BalanceSummaryCard`, `StatPill`, `TransactionsList`,
  `TransactionsEmptyState`, `UndoSnackBarContent`), leaving the screen file
  as pure composition and state wiring.
- Restyled `TransactionTile` and `AddTransactionSheet` to match the new
  visual language: circular type icons on income/expense wash colors,
  card-style rows, and a segmented add/expense toggle.
- Refreshed the app screenshots to reflect the new look.

## v0.1.0 — Reactive core

- `TransactionsBloc` made fully reactive via a single long-lived Drift
  `.watch()` subscription — add/delete no longer trigger a manual refetch.
- Added a DB-computed `BalanceCubit` stream and hardened amount parsing
  (exact minor-unit arithmetic, no floating-point drift).
- Full presentation layer: balance summary, swipe-to-delete with animated
  undo, and an add-transaction bottom sheet.
- Drift-backed `Transactions` schema, `TransactionsRepository`, and
  `AppBlocObserver` for full event/state logging.
- GitHub Actions CI running format checks, static analysis, and the full
  test suite on every PR into `main`.
