import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/category_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/category_card.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.categories),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => AddCategoryDialog.show(context),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_outlined,
              title: AppStrings.noCategories,
              subtitle: AppStrings.noCategoriesSubtitle,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryCard(
                category: category,
                onTap: () => context.push('/categories/${category.id}'),
                onLongPress: () =>
                    _showCategoryOptions(context, ref, category),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddCategoryDialog.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryOptions(
      BuildContext context, WidgetRef ref, category) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  AddCategoryDialog.show(context, category: category);
                },
              ),
              if (category.id != 1) // Don't allow deleting "General"
                ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Delete',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteCategory(context, ref, category);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCategory(
      BuildContext context, WidgetRef ref, category) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteCategory,
      message: AppStrings.deleteCategoryConfirm,
    );
    if (confirmed == true) {
      // Move tasks to General (id=1) before deleting
      await ref
          .read(taskNotifierProvider.notifier)
          .moveTasksToCategory(category.id, 1);
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);
    }
  }
}
