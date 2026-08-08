import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/data/models/transactions.dart';
import 'package:stockflow/transactions/data/transactions_data_source.dart'
    show Transaction;
import 'package:stockflow/transactions/presentation/format.dart';
import 'package:stockflow/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:stockflow/transactions/presentation/widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

const _undoDuration = Duration(seconds: 5);

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Ids that have been swiped away but whose delete is still pending
  // (i.e. the user might still hit Undo). Hiding them locally keeps the
  // rendered list in sync with what Dismissible already removed, instead
  // of waiting on the bloc's async delete + refresh round trip.
  final Set<String> _pendingDeleteIds = {};

  @override
  void initState() {
    super.initState();
    context.read<TransactionsBloc>().add(AppLaunchEvent());
  }

  void _handleSwipeToDelete(Transaction transaction) {
    setState(() => _pendingDeleteIds.add(transaction.id));

    final bloc = context.read<TransactionsBloc>();
    var undone = false;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: _UndoSnackBarContent(
              message: transaction.note?.isNotEmpty == true
                  ? 'Deleted "${transaction.note}"'
                  : 'Transaction deleted',
              duration: _undoDuration,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                undone = true;
                if (!mounted) return;
                setState(() => _pendingDeleteIds.remove(transaction.id));
              },
            ),
            duration: _undoDuration,
          ),
        )
        .closed
        .then((_) {
          if (undone) return;
          bloc.add(DeleteTransactionEvent(id: transaction.id));
          // _pendingDeleteIds is pruned in build() once the bloc confirms
          // the row is actually gone, so it never grows unbounded.
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          final allData = switch (state) {
            TransactionsInitial() => null,
            Loaded(:final data) => data,
            TransactionsError(:final previousData) => previousData,
          };

          if (state is TransactionsError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            });
          }

          if (allData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is Loaded && _pendingDeleteIds.isNotEmpty) {
            final stillPresent = allData.map((t) => t.id).toSet();
            final confirmedGone = _pendingDeleteIds
                .where((id) => !stillPresent.contains(id))
                .toList();
            if (confirmedGone.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _pendingDeleteIds.removeAll(confirmedGone));
              });
            }
          }

          final data = _pendingDeleteIds.isEmpty
              ? allData
              : allData
                    .where((t) => !_pendingDeleteIds.contains(t.id))
                    .toList();

          return Column(
            children: [
              _BalanceSummary(data: data),
              Expanded(
                child: data.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: data.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final transaction = data[index];
                          return TransactionTile(
                            transaction: transaction,
                            onDelete: () => _handleSwipeToDelete(transaction),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _UndoSnackBarContent extends StatefulWidget {
  const _UndoSnackBarContent({required this.message, required this.duration});

  final String message;
  final Duration duration;

  @override
  State<_UndoSnackBarContent> createState() => _UndoSnackBarContentState();
}

class _UndoSnackBarContentState extends State<_UndoSnackBarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.message),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => LinearProgressIndicator(
              value: 1 - _controller.value,
              minHeight: 3,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white70),
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.data});

  final List<Transaction> data;

  @override
  Widget build(BuildContext context) {
    final income = data
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amountMinor);
    final expense = data
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amountMinor);
    final balance = income - expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatAmountMinor(balance),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.green.shade700,
                      label: 'Income',
                      amountMinor: income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.red.shade700,
                      label: 'Expense',
                      amountMinor: expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.amountMinor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  formatAmountMinor(amountMinor),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first one',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
