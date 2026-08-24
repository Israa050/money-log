import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stockflow/core/service_locator.dart';
import 'package:stockflow/core/theme/app_colors.dart';
import 'package:stockflow/features/categories/bloc/categories_bloc.dart';
import 'package:stockflow/features/categories/presentation/widgets/category_editor_sheet.dart';
import 'package:stockflow/features/categories/presentation/widgets/category_list_tile.dart';
import 'package:stockflow/features/categories/presentation/widgets/delete_category_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoriesBloc>()..add(CategoriesStarted()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: BlocConsumer<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is CategoriesError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final categories = switch (state) {
            CategoriesInitial() => null,
            CategoriesLoaded(:final data) => data,
            CategoriesError(:final previousData) => previousData,
          };

          if (categories == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No categories yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.inkFaint),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryListTile(
                category: category,
                onEdit: () =>
                    showCategoryEditorSheet(context, category: category),
                onDelete: () => showDeleteCategoryDialog(context, category),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryEditorSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
