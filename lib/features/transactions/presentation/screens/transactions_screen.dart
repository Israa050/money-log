import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/features/backup/presentation/widgets/export_action.dart';
import 'package:stockflow/features/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/features/categories/domain/entities/category_entity.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:stockflow/features/transactions/domain/entities/transaction_type.dart';
import 'package:stockflow/features/categories/presentation/screens/categories_screen.dart';
import 'package:stockflow/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:stockflow/features/transactions/presentation/widgets/balance_summary_card.dart';
import 'package:stockflow/features/categories/presentation/widgets/category_totals_card.dart';
import 'package:stockflow/features/transactions/presentation/widgets/transactions_list.dart';
import 'package:stockflow/features/transactions/presentation/widgets/undo_snackbar_content.dart';

const _undoDuration = Duration(seconds: 5);

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

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

  void _handleSwipeToDelete(TransactionEntity transaction) {
    setState(() => _pendingDeleteIds.add(transaction.id));

    final bloc = context.read<TransactionsBloc>();
    var undone = false;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: UndoSnackBarContent(
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
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          const ExportAction(),
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'Manage categories',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
        ],
      ),
      body: BlocBuilder<TransactionsBloc, TransactionsState>(
        builder: (context, state) {
          final allData = switch (state) {
            TransactionsInitial() => null,
            Loaded(:final data) => data,
            TransactionsError(:final previousData) => previousData,
          };
          final categories = switch (state) {
            Loaded(:final categories) => categories,
            _ => const <CategoryEntity>[],
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

          final income = data
              .where((t) => t.type == TransactionType.income)
              .fold<int>(0, (sum, t) => sum + t.amountMinor);
          final expense = data
              .where((t) => t.type == TransactionType.expense)
              .fold<int>(0, (sum, t) => sum + t.amountMinor);

          return Column(
            children: [
              BalanceSummaryCard(income: income, expense: expense),
              const CategoryTotalsCard(),
              Expanded(
                child: TransactionsList(
                  data: data,
                  onDelete: _handleSwipeToDelete,
                  categories: categories,
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
