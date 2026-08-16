import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/theme/app_colors.dart';
import 'package:stockflow/transactions/bloc/transactions_bloc.dart';
import 'package:stockflow/transactions/domain/entities/category_entity.dart';
import 'package:stockflow/transactions/domain/entities/transaction_type.dart';
import 'package:stockflow/transactions/presentation/format.dart';

Future<void> showAddTransactionSheet(BuildContext context) {
  final bloc = context.read<TransactionsBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        BlocProvider.value(value: bloc, child: const AddTransactionSheet()),
  );
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  bool _isSubmitting = false;
  String? _categoryId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final value = int.tryParse(hex.replaceFirst('#', 'FF'), radix: 16);
    return value == null ? null : Color(value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Guaranteed non-null: the form validator below already rejects any
    // input parseAmountToMinor would reject.
    final amountMinor = parseAmountToMinor(_amountController.text)!;
    final note = _noteController.text.trim();

    setState(() => _isSubmitting = true);

    context.read<TransactionsBloc>().add(
      AddTransactionEvent(
        amountMinor: amountMinor,
        type: _type,
        note: note.isEmpty ? null : note,
        categoryId: _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final state = context.watch<TransactionsBloc>().state;
    final categories = state is Loaded ? state.categories : <CategoryEntity>[];
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: BlocListener<TransactionsBloc, TransactionsState>(
        listenWhen: (previous, current) => _isSubmitting,
        listener: (context, state) {
          if (state is TransactionsError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is Loaded) {
            Navigator.of(context).pop();
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add transaction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.remove),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.add),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    setState(() => _type = selection.first),
              ),
              const SizedBox(height: 16),
              if (categories.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: categories.map((category) {
                    final categoryColor = _parseHex(category.colorHex);
                    return ChoiceChip(
                      avatar: categoryColor == null
                          ? null
                          : CircleAvatar(backgroundColor: categoryColor),
                      label: Text(category.name),
                      selected: _categoryId == category.id,
                      selectedColor: categoryColor?.withValues(alpha: 0.3),
                      onSelected: (selected) {
                        setState(
                          () => _categoryId = selected ? category.id : null,
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Enter an amount';
                  if (parseAmountToMinor(trimmed) == null) {
                    return 'Enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.accentInk,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
