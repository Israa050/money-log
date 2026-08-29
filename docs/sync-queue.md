# Sync queue (transactional outbox)

How local writes are recorded for a future server sync, why every write is
queued unconditionally, and what is deliberately not built yet.

## Overview

```
user adds / edits / deletes a transaction or category
        │
        ▼
TransactionsRepositoryImpl / CategoryRepositoryImpl
        │
        ▼  dataSource.transaction(() async {  ← single Drift transaction
        │     1. write the row to the local DB
        │     2. syncQueueRepository.enqueue(...)   ← ALWAYS, online or offline
        │     3. if enqueue returned Failure -> throw  ← forces rollback of (1)
        │  })
        ▼
sync_queue_entries table   (one row per mutation, never dropped yet)
        │
        ▼
watchPendingCount()  →  PendingSyncCubit  →  pending-changes badge in the UI
```

Relevant code:

- `lib/core/sync/domain/repositories/sync_queue_repository.dart` — the contract
- `lib/core/sync/data/repos/sync_queue_repository_impl.dart` — `enqueue`, `watchPendingCount`
- `lib/core/sync/data/models/sync_queue_entries.dart` — the Drift table
- `lib/features/transactions/data/repos/transactions_repository_impl.dart` — `addTransaction` / `deleteTransaction`
- `lib/features/categories/data/repos/category_repository_impl.dart` — `addCategory` / `updateCategory` / `deleteCategory`

## The decision: always enqueue (Option A)

Every mutating repository method enqueues a sync-queue row for the change **in
the same transaction as the local write**, regardless of the current
`NetworkStatus`. The row is the durable record of "the server does not know
about this change yet."

The rejected alternative (Option B) was: enqueue only when the device is
offline at write time, and write straight through when online.

### Why Option A

| Reason | Detail |
| --- | --- |
| Connectivity is not reachability | `connectivity_plus` reports whether a network *interface* is up (wifi / cellular), not whether the server is actually reachable. "Online" can still mean captive portal, DNS failure, server down, VPN split-brain. Gating enqueue on `NetworkStatus.online` would silently drop changes that only *looked* online. |
| No lost writes | A change made while genuinely online still is not on the server until a sync process pushes it and the server acknowledges. Until then it must live in the queue like any offline change. |
| One invariant to reason about | "Every local mutation has a queue row until a drain process removes it." Option B splits this into two cases and creates a reconciliation problem when connectivity flaps *during* a write. |
| Atomicity is already handled | The write and the enqueue share one `dataSource.transaction()`. Drift only rolls back on a thrown exception, so `enqueue` returning `Failure` is re-thrown inside the transaction and then converted back to a `Result` for the caller. Either both the row and its queue entry land, or neither does. |
| `enqueue` failure is a DB failure, not a network failure | `enqueue` does a local insert. It cannot fail because the network is down — only because the database itself is broken, in which case failing the whole write is correct. |

### Consequence: keep it

Do not "optimize" this by skipping the enqueue when online. If you are adding a
new mutating repository method, it must enqueue inside the same transaction and
re-throw on `Failure`, exactly like the existing five methods.

## What is deliberately NOT built yet

1. **No drain / push process.** Nothing reads the queue and sends it to a
   server. There is no server.
2. **`watchPendingCount()` counts every row.** There is no `synced` / `status`
   column, so the count only ever grows as the user makes changes. The UI badge
   therefore means "changes recorded locally since install", not "changes that
   failed to sync". UI copy is worded accordingly ("N pending", never
   "N failed"). See the comment in `sync_queue_repository.dart`.
3. **No coalescing.** Editing the same entity five times writes five rows. A
   real sync story needs compaction (last-write-wins per entity, or a proper
   op-log) before this ships.
4. **No retry / backoff / conflict resolution.** All future work.

### Before this becomes a real sync feature

- add a `status` (or `syncedAt`) column and change `watchPendingCount()` to
  filter to unsynced rows
- add a drain process (connectivity-triggered + periodic) that pushes rows and
  marks/deletes them
- decide the coalescing strategy
- decide server-conflict handling
