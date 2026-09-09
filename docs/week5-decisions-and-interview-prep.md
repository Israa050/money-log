# Week 5 — Technical Decisions, Trade-offs & Interview Prep

**Project:** StockFlow (money-log) · **Branch:** `feature/supabase_sync` → merged to `main` via PR #26
**Scope:** Supabase backend + push sync on top of the Week 4 offline outbox.

This document captures every technical decision made during the Week 5 build, the alternatives that were considered and rejected, the files changed, and a set of interview questions to practice against.

---

## Part 1 — Decision Log

Each entry: the decision, why, what was rejected, and where it lives in the code.

---

### D1 · Secrets via `--dart-define-from-file`, not a committed constant

**Decision:** Supabase URL and anon key are supplied at build time from a gitignored `env.json`, read through `String.fromEnvironment` in `SupabaseConfig`.

**Pros**
- No new dependency (compare `flutter_dotenv`).
- Secrets never enter git history; `env.example.json` documents the shape for other developers.
- Standard, first-class Flutter mechanism.

**Cons**
- Compile-time only — changing a value requires a rebuild, not just an app restart.
- Easy to forget the flag; a plain `flutter run` produces empty strings, not an error, so it needs an explicit guard (added: `SupabaseConfig.isConfigured` throws a `StateError` at startup).
- IDE run buttons don't pass it by default → needed a `.vscode/launch.json`.

**Alternatives rejected**
- `flutter_dotenv` — runtime `.env` reading. Rejected: extra dependency for a value that never changes between restarts anyway.
- Hardcoded consts in a gitignored Dart file — rejected: a gitignored source file is easy to accidentally `git add -f`, and it breaks CI builds silently.

**Note:** the anon key is *designed* to be public (it's shipped in every client app and protected by RLS). Keeping it out of git is hygiene, not a security boundary. The `service_role` key is the one that must never ship.

**Files:** `lib/core/env/supabase_config.dart`, `env.json` (gitignored), `env.example.json`, `.gitignore`, `.vscode/launch.json`

---

### D2 · Anonymous auth now, email/password deferred

**Decision:** `signInAnonymously()` in `main()` before `runApp`, guarded by a `currentUser == null` check.

**Pros**
- Fastest path to a non-null `auth.uid()`, which is what RLS actually needs.
- Zero UI work — unblocks the entire sync pipeline in one line.

**Cons**
- **Each install mints a brand-new `auth.uid()`.** There is no durable identity, so data cannot follow a user across devices or reinstalls.
- This directly caused the default-categories problem (see D9).
- A `TODO(auth)` and a dashboard toggle (Authentication → Providers → Anonymous Sign-Ins) are load-bearing but invisible in code.

**Alternatives rejected**
- Email/password now — correct long-term, but a day of UI work standing between us and testing the actual sync logic.

**Files:** `lib/main.dart:34-44`

---

### D3 · Register `SupabaseClient` as a plain GetIt singleton

**Decision:** `getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)` — a raw client, not wrapped in a repository.

**Pros**
- Matches the brief's literal instruction ("register alongside your other singletons").
- Anything needing Supabase injects the client rather than reaching for the `Supabase.instance` global → testable/mockable.
- Doesn't invent an `AuthRepository` abstraction before there's an auth feature to justify it.

**Cons**
- A raw third-party SDK type now sits in the DI graph, which is a slight break from the otherwise-uniform repository/use-case layering.

**Alternatives rejected**
- Wrapping in `AuthRepository` immediately — rejected as speculative; revisit when real auth lands.

**Files:** `lib/core/service_locator.dart:45-46`

---

### D4 · `SyncRepository` as a *new* class, not a method on `SyncQueueRepository`

**Decision:** `SyncQueueRepository` stays local-only (Drift: enqueue / getPending / dequeue). A new `SyncRepository` composes it with `SupabaseSyncDataSource` and owns `pushPending()`.

**Pros**
- Single Responsibility: "what's queued locally" and "how do I get it to the server" are two reasons to change, so two classes.
- `SyncQueueRepository` stays unit-testable with no network mocking at all.
- Mirrors the existing composition pattern (`TransactionsRepositoryImpl` already depends on `SyncQueueRepository`).

**Cons**
- One more interface + impl + DI registration for what could have been one method.

**Alternatives rejected**
- Adding `pushPending()` to `SyncQueueRepositoryImpl` and injecting Supabase into it — rejected explicitly on SRP grounds; it would drag a network dependency into every `enqueue`/`dequeue` test.

**Files:** `lib/core/sync/domain/repositories/sync_repository.dart`, `lib/core/sync/data/repos/sync_repository_impl.dart`

---

### D5 · `pushPending()` returns `Result<int>` = count of *fully completed* rows

**Decision:** Returns the number of entries that were both pushed **and** dequeued. If `pushEntry` succeeds but `dequeue` fails, it is **not** counted.

**Pros**
- The returned number means exactly one thing: "rows that actually left the queue."
- Consistent with existing `Result<int>` methods (`enqueue`, `deleteTransaction` return row counts).
- Harmless if a dequeue fails — the row is re-pushed next pass, and upsert is idempotent.

**Cons**
- Callers can't distinguish "3 succeeded, 0 failed" from "3 succeeded, 7 failed" without also reading the queue count.

**Alternatives rejected**
- `Result<PushSummary>` with succeeded + failed counts — rejected as speculative; no UI reads it yet.
- `Result<void>` — rejected as too coarse for the Day 4 manual verification.
- Counting a row as succeeded as soon as the push returned — rejected: overstates how many rows actually left the queue.

**Files:** `lib/core/sync/domain/repositories/sync_repository.dart`

---

### D6 · No `status` column — presence in the queue *is* the state (brief §2)

**Decision:** No status, retry-count, or error columns on `SyncQueueEntries`. A row exists ⟺ it hasn't successfully pushed. Failed rows stay put and are retried wholesale next pass. Per-row `try/catch` inside the loop so row 3 failing doesn't stop rows 4 and 5.

**Pros**
- Zero bookkeeping, zero migration.
- Correct *because* pushes are idempotent — `upsert` is insert-or-update keyed on PK; `delete().eq('id',…)` on an already-gone row affects 0 rows and does **not** throw.
- Independent row processing means one bad row = "one row behind," not "sync is broken."

**Cons**
- A permanently-failing row (e.g. a schema mismatch) retries forever with no backoff and no visibility — which is *exactly* what bit us in the `default-food` UUID incident (D9), and is why per-row error logging had to be added (D8).

**Alternatives rejected**
- Adding `status` / retry counts / exponential backoff / dead-letter queue now — rejected per the brief: solves problems that don't exist at solo-user scale.

**Files:** `lib/core/sync/data/repos/sync_repository_impl.dart:28-52`

---

### D7 · `user_id` + snake_case mapping happens at the push boundary — **the headline decision (brief §1)**

**Decision:** Local Drift models and local sync-queue payloads are untouched. `SupabaseSyncDataSource._mapForSupabase()` translates the local payload into the remote shape immediately before `.upsert()`: renames camelCase → snake_case (`amountMinor`→`amount_minor`, `colorHex`→`color_hex`, `occurredTime`→`occurred_at`) and stamps `'user_id': client.auth.currentUser!.id`.

**Why it belongs at the boundary (the defence the brief asks for):**
> The local database serves exactly one user implicitly — the device owner — so "whose row is this?" is not a question the local domain has to answer. Supabase is one shared Postgres holding many users' rows, so RLS needs `user_id` to be explicit. That difference is a property of the *destination*, not of the domain object. The domain model models the problem (a transaction has an amount, a type, a date); local storage and the remote API are just two different transports for it. Putting `user_id` in the shared model would let a transport concern leak into every layer that touches a `Transaction`.

**A second, concrete payoff:** the sync queue can hold rows enqueued *before* an app update. Because the queue stores the local format and mapping happens at push time, a new app version can correctly push old queued rows just by updating the mapper. Had the payloads been written in remote shape, a remote column rename would strand already-queued rows in a stale format.

**Pros**
- Local models never learn about Supabase.
- One small function is the entire cost of the divergence.
- Insulates queued data from remote schema changes.

**Cons**
- The mapper hand-writes a field-by-field translation per entity type; it grows with each new synced entity.
- `currentUser!` force-unwraps — safe only because `main()` guarantees a session before `runApp`, which is an invariant enforced by convention rather than by types.

**Alternatives rejected**
- Adding `user_id` to the Drift tables and the domain model — rejected: exactly the leak the brief warns about.
- Writing snake_case + `user_id` into the payload at `enqueue()` time — rejected: couples locally-queued rows to the remote schema and breaks the stale-queue case above.
- Per-type mapper registry instead of a `switch` — rejected for now at 2 entity types; revisit if the list grows.

**Files:** `lib/core/sync/data/datasources/supabase_sync_data_source.dart`

---

### D8 · Per-row error logging in `pushPending()`

**Decision:** The per-row `catch` logs entity type, id, operation, and the exception before `continue`.

**Why it exists:** the original `catch (_) { continue; }` was *silently* swallowing every failure. Two transactions failed to sync and there was no way to see why — no crash, no message, just a queue count that wouldn't drop. Adding this log is what surfaced the real `PostgrestException` and led to D9.

**Trade-off:** slightly noisier logs in exchange for any persistent, never-going-to-succeed failure being visible instead of invisible. Given D6 deliberately has no error column, logging is the *only* diagnostic channel.

**Files:** `lib/core/sync/data/repos/sync_repository_impl.dart:31-45`

---

### D9 · Default category ids changed from `'default-food'` to real UUIDs

**The bug:** `PostgrestException(message: invalid input syntax for type uuid: "default-food", code: 22P02)`. The four seeded default categories used human-readable string ids, but Supabase's `id`/`category_id` columns are typed `uuid`. Any transaction referencing a default category was rejected on push. Meanwhile user-created categories (real `Uuid().v4()`) synced fine — hence "1 synced, 2 didn't."

**Decision:** replace the seed ids with fixed UUID literals exported as constants (`defaultCategoryFoodId`, …).

**Pros** · Ids are now valid everywhere with no special-casing. Fixed (not random) values keep them stable and assertable in tests.
**Cons** · Only fixes fresh installs (`onCreate`); existing devices need a reinstall or a migration. Accepted — pre-launch, no real data to preserve.

**Alternatives rejected**
- Special-casing the 4 known ids in the mapper — rejected: pushes a data problem into the sync layer forever.
- A Drift `onUpgrade` migration to rename them in place — rejected: unnecessary pre-launch.

**Files:** `lib/features/transactions/data/transactions_data_source.dart:10-40`, `test/database_test.dart`

---

### D10 · Default-category *sync* was built, then deliberately reverted — **open gap**

**The problem:** the 4 defaults are inserted directly by Drift's `onCreate` via `batch()`, bypassing `CategoryRepositoryImpl.addCategory()` — so they are **never enqueued** and never reach Supabase for any user.

**What was built:** `CategoryRepository.enqueueDefaultCategories()`, called once from `main()`.

**Why it was reverted:** no good guard existed. A "check the queue first" guard only prevents duplicates while rows are *still pending* — after the first successful sync they're dequeued, so the next launch re-enqueues them, forever. The correct fix needed a persisted flag (a `shared_preferences` dependency) or accepting unbounded queue growth. Neither was worth it, so the rows are seeded manually via SQL for the current test user instead.

**Consequence (known, accepted, documented):** because anonymous auth mints a new `auth.uid()` per install (D2), the manual seed only works for one test session. A fresh install or a real user won't have those category rows, and any transaction referencing a default category will fail a foreign-key check. **Deferred until real auth exists** — the clean fix is then either a Postgres trigger on `auth.users` insert, or a client-side once-per-account seed.

**Alternatives rejected**
- Persisted `shared_preferences` flag — viable, rejected to avoid the dependency for a cosmetic guard.
- Re-enqueue every launch and accept the churn — rejected as unbounded local growth.

---

### D11 · `SyncCubit` — a `Cubit<void>` that owns the auto-trigger

**Decision:** A stateless cubit whose only job is to own subscriptions and fire `pushPending()`.

**Pros** · Matches the existing `ConnectivityCubit`/`PendingSyncCubit` pattern. No speculative "isSyncing" state that nothing reads.
**Cons** · A `Cubit` that never emits is slightly unusual; `BlocProvider.value` exists purely to force construction, not to supply state to the tree.

**Key insight — no manual "previous state" tracking needed:** `bloc`'s `Cubit.stream` is `distinct()` by default, so *every* emission of `online` on that stream already **is** a transition into online.

**Alternatives rejected** · An `idle/syncing/success/error` state enum — deferred until a UI actually consumes it.

**Files:** `lib/core/sync/cubit/sync_cubit.dart`

---

### D12 · Second trigger: push when the pending count *increases*

**The bug:** with only the connectivity listener, sync fired at launch (queue empty) and on reconnect — but **never when a change was made while already online**, because adding a transaction doesn't change `NetworkStatus`, so the distinct-ed stream never emits. The only way to sync was toggling wifi off and on.

**Decision:** `SyncCubit` also listens to `PendingSyncCubit`'s count stream and pushes when the count **increases** while online.

**Pros** · Reuses an existing live signal — repositories stay untouched, and "when to sync" stays in one class. Increase-only avoids a redundant push immediately after a successful dequeue lowers the count.
**Cons** · An indirect trigger (a UI-facing count cubit now drives sync); `_lastPendingCount` is mutable state to keep in sync.

**Alternatives rejected** · Repositories calling a push use-case directly after `enqueue()` — rejected: scatters the sync-triggering decision across every feature repository.

**Files:** `lib/core/sync/cubit/sync_cubit.dart`, `lib/core/service_locator.dart`

---

### D13 · Timestamps set explicitly in Dart, not via Drift's DB default

**Decision:** `addTransaction` computes `DateTime.now().toUtc()` once and passes it to *both* the Drift insert and the sync payload.

**Why:** Postgres `occurred_at`/`created_at` are `NOT NULL` with no default, but those values only existed as a Drift-side `currentDateAndTime` default and never made it into the queue payload.

**Pros** · One instant, guaranteed identical locally and remotely, with no read-back query.
**Cons** · Drift's column default becomes dead code on this path.
**Alternatives rejected** · Insert then re-read the row to get the generated timestamps — a second round-trip plus a new query method for the same guarantee.

**Files:** `lib/features/transactions/data/repos/transactions_repository_impl.dart:58-80`

---

### D14 · `entityType` → table name mapped in the data source

**Decision:** the queue keeps singular `'transaction'`/`'category'`; a `_tableNames` lookup in `SupabaseSyncDataSource` maps to plural table names at push time.

**Pros** · No change to already-shipped enqueue call sites or already-queued rows. Same reasoning as D7.
**Cons** · Two naming conventions coexist.
**Alternatives rejected** · Changing `enqueue()` calls to pass plural names — would strand rows queued under the old convention.

**Bug caught in review:** the fallback was written `?? entry.entityId` (a UUID) instead of `?? entry.entityType` — would have pushed to a table named after a random UUID. Fixed.

---

## Part 2 — Files Changed

### New files
| File | Purpose |
|---|---|
| `lib/core/env/supabase_config.dart` | Reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from dart-defines; `isConfigured` guard |
| `lib/core/sync/data/datasources/supabase_sync_data_source.dart` | `pushEntry()`; table-name + field mapping; `user_id` stamping |
| `lib/core/sync/domain/repositories/sync_repository.dart` | `pushPending() → Future<Result<int>>` |
| `lib/core/sync/data/repos/sync_repository_impl.dart` | Loop, per-row try/catch, dequeue-on-success, error logging |
| `lib/core/sync/domain/usecases/push_pending_changes_usecase.dart` | Thin `call()` wrapper |
| `lib/core/sync/cubit/sync_cubit.dart` | Auto-trigger on reconnect **and** on queue-count increase |
| `env.example.json` | Committed template |
| `.vscode/launch.json` | Run configs that pass `--dart-define-from-file` |

### Modified files
| File | Change |
|---|---|
| `pubspec.yaml` / `pubspec.lock` | `supabase_flutter: ^2.17.2` + transitives |
| `lib/main.dart` | `Supabase.initialize(publishableKey:)`, anonymous sign-in, assert + log, `SyncCubit` provider |
| `lib/core/service_locator.dart` | Registered `SupabaseClient`, `SupabaseSyncDataSource`, `SyncRepository`, `PushPendingChangesUseCase`, `SyncCubit`; reordered `PendingSyncCubit` before `SyncCubit` |
| `lib/core/sync/domain/repositories/sync_queue_repository.dart` | Added `getPending()` / `dequeue()`, both `Result<T>`-wrapped |
| `lib/core/sync/data/repos/sync_queue_repository_impl.dart` | Implemented both + row→entity mapper |
| `lib/features/transactions/data/transactions_data_source.dart` | `getAllSyncQueueEntries()`, `deleteSyncQueueEntry()`, UUID default-category ids |
| `lib/features/transactions/data/repos/transactions_repository_impl.dart` | Explicit timestamps in row + payload |
| `lib/core/sync/cubit/pending_sync_cubit.dart` | Corrected stale "no drain process yet" doc comment |
| `test/database_test.dart` | Assert new UUID constants |
| `test/widget_test.dart` | Stub `PushPendingChangesUseCase`, register `SyncCubit` |
| `.gitignore` | Ignore `env.json` |

### Review catches worth remembering
1. `getPending()`/`dequeue()` first written returning bare types — corrected to `Result<T>` to match the layer and to stop an exception aborting a whole push pass.
2. `_tableNames` fallback used `entityId` instead of `entityType` (D14).
3. `SyncCubit` nearly imported `features/categories/…` — caught as a `core → features` layering inversion; trigger moved to `main.dart` instead (before that path was reverted entirely, D10).
4. Deprecated `anonKey:` → `publishableKey:`.

---

## Part 3 — Week 5 Brief: Status Check

### Definition of Done
| Item | Status | Notes |
|---|---|---|
| Supabase project live; remote schema + `user_id` divergence | ✅ | Tables + RLS exist; verified via `information_schema` / `pg_policies` |
| Auth working (`currentUser` non-null) | ✅ | Anonymous; asserted and logged at startup |
| Push reads queue, pushes independently, dequeues on success | ✅ | `SyncRepositoryImpl.pushPending()` |
| Failed pushes stay queued, retry safely, no status column | ✅ | Verified live: 1 pushed, 1 failed and remained |
| Auto-trigger on connectivity regained | ✅ | `SyncCubit` |
| **Manual "Sync now" button + status indicator** | ❌ | **Not built** |
| Basic RLS enabled and tested | ⚠️ | Enabled and *proven* by the live push; no automated test |
| **Tests with a mocked Supabase client** | ❌ | **Not written** — no `SupabaseSyncDataSource` or `pushPending()` unit tests exist |
| Schema-divergence decision defended in writing | ✅ | D7 above |
| 4 recursion problems in Dart | ❔ | Outside this conversation |
| English spoken daily | ❔ | Outside this conversation |

### Day-by-day
- **Day 1** — Supabase project, remote schema, RLS policies: ✅ (schema/policies confirmed by SQL inspection)
- **Day 2** — `supabase_flutter`, `Supabase.initialize`, auth, DI registration: ✅
- **Day 3** — `pushEntry`, `pushPending()`, `PushPendingChangesUseCase` + registration: ✅
- **Day 4** — auto-trigger: ✅ (plus D12, a gap the brief didn't anticipate). Deliberate mid-push network kill: ⚠️ *not performed as a scripted test* — but failure handling was proven accidentally and more convincingly by the real `PostgrestException`: the failing row stayed queued, the other pushed, nothing crashed.
- **Day 5** — mocked-Supabase tests ❌, "Sync now" button ❌, `flutter analyze` ✅ clean, PR merged ✅ (#26)
- **Day 6** — RLS ✅, decision defended ✅ (D7)

### Outstanding work, highest value first
1. **Mocked-Supabase tests** (Day 5) — the largest gap. `pushPending()`'s independent-row behaviour is the week's core claim and is currently untested. Suggested cases: upsert called with correctly mapped payload incl. `user_id`; delete calls `.eq('id',…)`; success dequeues; failure leaves the row *and* still attempts later rows; `getPending()` failure returns `Failure` without looping.
2. **"Sync now" button + status indicator** (Day 5) — would likely justify revisiting D11 (a real `SyncCubit` state).
3. **Default categories for real users** (D10) — blocked on real auth.
4. **Remove the TEMP DIAGNOSTIC logging** in `sync_repository_impl.dart` — tidy the three-line diagnostic back into one line now that the bug is found.
5. **Commit the current work** — everything after PR #26 (D9, D12, D13, the mapper, `SyncCubit`) is still uncommitted on `main`.

---

## Part 4 — Interview Questions

### Tier 1 — The brief's own self-check
1. Why does the remote schema have a `user_id` column the local one doesn't — and where exactly is that value added?
2. Why is it safe to skip a `status` column even now that pushes can fail?
3. What does "idempotent" mean for `.upsert()`, and why does it matter for retry safety?
4. Why process queue rows independently instead of stopping at the first failure?
5. What does Row Level Security actually check, and what would happen without it?
6. Two devices push a change to the same row while both online — what happens? *(Honest answer: last write wins. No conflict resolution — that's next week.)*

### Tier 2 — Design decisions
7. You created `SyncRepository` instead of adding `pushPending()` to `SyncQueueRepository`. Defend that against "you added a class to add a method."
8. `pushPending()` returns a count of succeeded rows. What exactly does that number mean when a push succeeds but the dequeue fails — and why did you choose that?
9. Why does the mapping live in the data source rather than in the payload builders? Give the concrete failure case that decision prevents.
10. You have no `status` column but you *did* add error logging. Isn't that a contradiction?
11. Why is `SyncCubit` a `Cubit<void>`? When would you give it real state?
12. Your local ids are `String`, remote is `uuid`. What did that mismatch cost you, and how would you catch it earlier next time?

### Tier 3 — Debugging narratives (strongest material)
13. **The `.name` red herring.** Logs showed `NoSuchMethodError: Class 'OperationType' has no instance getter 'name'` on statically-valid Dart. Walk through how you'd isolate that. *(Key: the trace pointed at the catch site, not the throw site; the real `PostgrestException` was hidden behind interleaved log output. The fix was splitting the diagnostic into separate log calls so no single interpolation could mask the original error.)*
14. **"One synced, two didn't."** How do you diagnose a partial sync failure? *(Answer: the partial success is itself the clue — user-created categories had real UUIDs; the failures all referenced `'default-food'`.)*
15. **The invisible auto-trigger.** Sync only fired after toggling wifi. Why? *(`Cubit.stream` is `distinct()`; adding a transaction doesn't change `NetworkStatus`, so nothing emitted. Fixed by also listening to the queue count.)*
16. `SyncCubit` is a lazy GetIt singleton constructed inside `MultiBlocProvider`. What does that imply about when the first push attempt happens, and why did it always report `0 change(s) pushed`?

### Tier 4 — Architecture & trade-offs
17. Where's the boundary between `core/` and `features/` here, and what did you catch yourself nearly violating? *(`SyncCubit` importing `CategoryRepository`.)*
18. You built `enqueueDefaultCategories()` then reverted it. Walk through why — and defend reverting working code.
19. Anonymous auth gives a new `auth.uid()` per install. What breaks, and what would you change first?
20. Someone extracts your anon key from the APK. What can they do, and what stops them?
21. Talk me through the layers a single "add transaction" traverses, from tap to Postgres row.
22. What would you build first if this went from one user to a thousand?

### Tier 5 — Rapid fire
23. Why `Result<T>` instead of throwing?
24. Why must a `Failure` be re-thrown inside Drift's `transaction()`? *(Drift only rolls back on a thrown exception, not a returned value.)*
25. Why is `dequeue` deliberately not an error when 0 rows are affected?
26. Why fixed UUID literals for default categories instead of `Uuid().v4()` at seed time?
27. What does `--dart-define-from-file` do that a `.env` file can't, and vice versa?
28. Why does `pushEntry` throw rather than return a `Result`?

### Strongest talking points
- **D7** is the week's headline: a crisp, defensible boundary decision with two independent justifications (domain purity *and* stale-queue resilience).
- **D6 + D12 together** show the difference between a design that's correct on paper and one that's correct in the hand.
- **D8/D9** are the best "I debugged something real" story: a red-herring error, a partial failure, and a root cause in seeded data.
- **D10** shows the judgement to *delete* working code and write down the debt instead of shipping a half-guard.

### Weakest points — prepare honest answers
- No mocked-Supabase tests, so the independent-row claim is unverified by CI.
- The Day 4 network-kill test was never run as a deliberate script.
- `currentUser!` force-unwraps on an invariant enforced only by `main()`'s ordering.
- Diagnostic logging is still in the code.
- Everything after PR #26 is uncommitted.
