import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/transactions/bloc/categories_bloc.dart';
import 'package:stockflow/transactions/domain/entities/category_entity.dart';

Future<void> showDeleteCategoryDialog(
  BuildContext context,
  CategoryEntity category,
) {
  final bloc = context.read<CategoriesBloc>();
  return showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete "${category.name}"?'),
      content: const Text(
        'Transactions using this category will become uncategorized. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            bloc.add(DeleteCategoryEvent(id: category.id));
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
