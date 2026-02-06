import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/category_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_tile.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final int categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final categoryAsync = ref.watch(categoryByIdProvider(widget.categoryId));
    final tasksAsync =
        ref.watch(categoryTasksStreamProvider(widget.categoryId));

    return Scaffold(
      appBar: AppBar(
        title: categoryAsync.when(
          data: (cat) => Text(cat.name),
          loading: () => const Text('...'),
          error: (_, __) => const Text('Category'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildToggleChip(AppStrings.active, !_showCompleted),
                const SizedBox(width: 8),
                _buildToggleChip(AppStrings.completed, _showCompleted),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = tasks
                    .where((tc) => tc.task.isCompleted == _showCompleted)
                    .toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: _showCompleted
                        ? 'No completed tasks'
                        : AppStrings.noTasks,
                    subtitle: _showCompleted
                        ? 'Complete some tasks to see them here'
                        : AppStrings.noTasksSubtitle,
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tc = filtered[index];
                    return TaskTile(
                      taskWithCategory: tc,
                      index: index,
                      onToggle: (value) {
                        ref
                            .read(taskNotifierProvider.notifier)
                            .toggleCompletion(tc.task.id, value ?? false);
                      },
                      onTap: () {
                        context.push('/tasks/edit/${tc.task.id}');
                      },
                      onDelete: () async {
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: AppStrings.deleteTask,
                          message: AppStrings.deleteTaskConfirm,
                        );
                        if (confirmed == true) {
                          ref
                              .read(taskNotifierProvider.notifier)
                              .deleteTask(tc.task.id);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/tasks/add?categoryId=${widget.categoryId}'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _showCompleted = label == AppStrings.completed);
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
      ),
      showCheckmark: false,
    );
  }
}
