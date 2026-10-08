# Release Notes

### v0.6.0 — Push sync to Supabase & manual "Sync now"

Adds the drain side of the transactional outbox described below, plus a
user-triggered path on top of it. See
[Push sync to Supabase](../README.md#push-sync-to-supabase) in the README for
the full design writeup and
[`week5-decisions-and-interview-prep.md`](week5-decisions-and-interview-prep.md)
for the decision log.

**Push sync**

- Added `lib/core/env/supabase_config.dart` (reads the URL/anon key from
  `--dart-define-from-file`) and wired `supabase_flutter`: `main()` now
  calls `Supabase.initialize` and `signInAnonymously()` before `runApp`.
- Added `SupabaseSyncDataSource` (`pushEntry`, `mapForSupabase`) and
  `SyncRepository`/`SyncRepositoryImpl.pushPending()` — reads the queue,
  pushes each row independently (one failure doesn't block the rest of the
  pass), dequeues on success, returns a count of fully-completed rows.
- `SyncCubit` — previously `Cubit<void>`, existing only to own two
  subscriptions — auto-triggers `pushPending()` on reconnect and on a
  pending-count increase while online.
- Fixed default category ids from human-readable strings (`'default-food'`)
  to real UUIDs — Supabase's `id` column is typed `uuid` and rejected the
  old values.

**Manual "Sync now"**

- `SyncCubit` is now `Cubit<SyncState>` (`SyncIdle` / `SyncInProgress` /
  `SyncCompleted` / `SyncFailure`, each carrying `isManual`) instead of
  `Cubit<void>`, plus a public `syncNow()` and an in-flight guard.
- Added `SyncNowButton` and `SyncSheet` (pending count, the button, an
  upload-only disclaimer, a manual-only result snackbar), opened by tapping
  `PendingSyncBadge` — which is now always visible instead of hidden at a
  zero count.

**Tests**

- `test/sync/sync_repository_impl_test.dart` — `pushPending()`'s
  independent-row processing, dequeue-on-success, and the
  `getPending()`-failure short-circuit.
- `test/sync/supabase_sync_data_source_test.dart` — `mapForSupabase()`'s
  camelCase→snake_case + `user_id`-stamping, tested directly rather than
  through `pushEntry()`'s Supabase calls (mocktail can't reliably intercept
  the SDK's `.upsert()` awaitable chain).
- Cubit/widget tests for `SyncCubit`'s new state and `SyncNowButton`/
  `SyncSheet` are still pending.

**Not built yet**

- Pull sync, per-row error messages in the UI (only pass/fail is inferred,
  not why), and syncing the default categories for a real account — see
  [Not yet done](../README.md#-not-yet-done) in the README.

### v0.5.0 — Connectivity & offline sync queue

Groups the connectivity layer, the transactional-outbox sync queue, and the
two UI affordances they drive (offline banner, pending-changes badge).

**Connectivity layer**

- Added `connectivity_plus` and a core, cross-cutting connectivity layer
  under `lib/core/connectivity/` (`ConnectivityRepository`/Impl,
  `WatchConnectivityUseCase`, `ConnectivityCubit`), all registered as
  `get_it` lazy singletons. Placed in `core/`, not as its own feature or
  inside `transactions/`, since network status is infrastructure any
  feature may depend on, not a business concern.
- The domain layer exposes a `NetworkStatus` enum instead of the plugin's
  `ConnectivityResult`, and treats "offline" as a normal
  `Success(NetworkStatus.offline)` rather than a `Result.failure` — `Failure`
  is reserved for actual connectivity-check errors.
- `_toNetworkStatus` maps the plugin's `List<ConnectivityResult>` with an
  "every result is `none`" rule (not "contains `none`"), so a single active
  interface among several inactive ones still reads as online.

**Offline sync queue (transactional outbox)**

- Added `lib/core/sync/`: a `SyncQueueEntries` Drift table (schema v4) plus
  `OperationType`, `SyncQueueRepository`/`Impl`, and
  `WatchPendingSyncCountUseCase` — the write side of a transactional
  outbox for later Supabase sync. See
  [Offline sync queue](../README.md#offline-sync-queue-transactional-outbox)
  in the README and [`sync-queue.md`](sync-queue.md) for the full design
  writeup (always-enqueue over connectivity-branching, atomic transaction +
  enqueue, snapshot-vs-pointer payload).
- `TransactionsRepositoryImpl` and `CategoryRepositoryImpl` wrap every
  write (`add`/`update`/`delete`) in a Drift `transaction()` alongside a
  `syncQueueRepository.enqueue(...)` call, so a transaction/category row and
  its sync-queue record either both commit or neither does.
- Reorganized the codebase from a single `lib/transactions/` folder into
  `lib/features/{transactions,categories}/` plus `lib/core/{connectivity,sync,theme}/`
  — `categories/` now has its own `bloc/domain/data/presentation` layers,
  separate from `transactions/`. The Drift database class itself
  (`transactions_data_source.dart`) still hosts the `Categories` and
  `SyncQueueEntries` table definitions alongside `Transactions`, since
  Drift's transaction/FK guarantees require every table sharing them to be
  in one `@DriftDatabase` class — only the table *definition files* and the
  surrounding CRUD/bloc/UI code moved.

**UI**

- `OfflineBanner` (`lib/core/connectivity/presentation/widgets/`) — a strip
  above the transaction list driven by `ConnectivityCubit`, shown while
  offline, collapsed (`AnimatedSize`) when online. Copy is informational
  ("changes are saved on this device"), not an error state.
- `PendingSyncCubit` (`lib/core/sync/cubit/`, a `Cubit<int>` over
  `watchPendingSyncCount()`) and `PendingSyncBadge`
  (`lib/core/sync/presentation/widgets/`) — an app-bar badge showing the
  queue count, hidden at zero. `WatchPendingSyncCountUseCase` and
  `PendingSyncCubit` are now registered in `service_locator.dart` (they
  existed but were unwired). Both cubits are provided app-wide via
  `BlocProvider.value` in `main.dart`.
- `transactions_screen.dart` body logic extracted to a private
  `_TransactionsBody` widget so the banner can sit outside the `BlocBuilder`
  (visible even during the initial loading spinner).

**Tests**

- `test/connectivity/` — `ConnectivityRepositoryImpl` (the mapping rule +
  the `checkConnectivity` error path + stream mapping), `ConnectivityCubit`
  (seed state, ordered emissions, `close()` cancels the subscription),
  `WatchConnectivityUseCase` passthrough.
- `test/sync/` — `SyncQueueRepositoryImpl` against a real in-memory Drift DB
  (`enqueue` id/`createdAt` generation, verbatim payload storage, operation
  enum round-trip, reactive `watchPendingCount`), `WatchPendingSyncCountUseCase`
  passthrough.
- `test/backup/export_serializer_test.dart` — `buildEnvelope`/`encodeExport`
  (fixed metadata, UTC `exportedAt`, `counts` derivation, JSON round-trip).
- `test/widget_test.dart` registers stub use cases for the two new cubits so
  `MyApp` still boots.
- Widget/cubit tests for `OfflineBanner`, `PendingSyncCubit`, and
  `PendingSyncBadge` are still pending — see
  [Not yet done](../README.md#-not-yet-done) in the README.

**Not built yet, as of this release**

- The background process that drains `SyncQueueEntries` and pushes to
  Supabase, and no Supabase client/project existed yet — both landed in
  the push-sync release above this one.

### v0.4.0 — Manage categories

- Added full category CRUD behind a new "Manage Categories" screen (opened
  from the transactions app bar): create, rename/recolor via a fixed
  swatch palette, and delete.
- Changed `transactions.categoryId`'s foreign key to `ON DELETE SET NULL`
  (schema v2 → v3, via a drift `TableMigration`) so deleting a category
  with transactions attached orphans them into "Uncategorized" instead of
  throwing a constraint error.
- `CategoryRepository.watchCategories()` replaced the old one-shot
  `getCategories()`, and `TransactionsBloc` now holds a second stream
  subscription for it — a category created, renamed, or deleted propagates
  to the add-transaction chips and transaction pills immediately.
- Added `addCategory`/`updateCategory`/`deleteCategory` (all `Result`-returning)
  with name validation — trimmed, non-empty, case-insensitive-duplicate
  rejected — enforced in the repository rather than a SQL constraint.
- Added a new `CategoriesBloc` for category mutation, kept separate from
  `TransactionsBloc` (which only reads categories), matching the existing
  `BalanceCubit`/`CategoryTotalsCubit` single-responsibility split.
- Added Drift-backed tests for category CRUD and the orphaning behavior,
  a `CategoryRepositoryImpl` test suite mirroring
  `transactions_repository_test.dart`, and mocktail-based
  `CategoriesBloc` tests mirroring `transactions_bloc_mocktail_test.dart`.

### v0.3.0 — Category totals & tags

- Added reactive total spending per category: a Drift `leftOuterJoin` +
  `groupBy` query (`TransactionsDataSource.categoryTotals`), wired through a
  new `CategoryTotalEntity`, `CategoryRepository.watchCategoryTotals()`,
  `WatchCategoryTotalsUsecase`, and `CategoryTotalsCubit` to a new
  `CategoryTotalsCard` on the transactions screen. Uncategorized spend
  surfaces as its own bucket instead of being dropped; income transactions
  never inflate a category's total.
- Made `CategoryTotalsCard` collapsible — tapping its header animates an
  expand/collapse to free space for the transaction list below.
- `TransactionEntity` now carries `categoryId`, and `TransactionTile` shows
  a color-coded category pill next to the transaction title when one is set.
- Fixed a pre-existing bottom-sheet overflow in `AddTransactionSheet` by
  wrapping its form `Column` in a `SingleChildScrollView`.

### v0.2.0 — Themed redesign

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

### v0.1.0 — Reactive core

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
