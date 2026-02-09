import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback_utils.dart';
import '../../providers/category_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/skeleton_loader.dart';
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
                        ? AppStrings.noCompletedTasks
                        : AppStrings.noTasks,
                    subtitle: _showCompleted
                        ? AppStrings.noCompletedSubtitle
                        : AppStrings.noTasksSubtitle,
                    actionLabel: _showCompleted ? null : AppStrings.createTask,
                    onAction: _showCompleted
                        ? null
                        : () => context.push(
                            '/tasks/add?categoryId=${widget.categoryId}'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        categoryTasksStreamProvider(widget.categoryId));
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tc = filtered[index];
                      return AnimatedListItem(
                        index: index,
                        child: TaskTile(
                          taskWithCategory: tc,
                          index: index,
                          onToggle: (value) {
                            ref
                                .read(taskNotifierProvider.notifier)
                                .toggleCompletion(
                                    tc.task.id, value ?? false);
                            if (value == true) {
                              AppFeedback.showSuccess(
                                  context, AppStrings.taskCompleted);
                            } else {
                              AppFeedback.showSuccess(
                                  context, AppStrings.taskRestored);
                            }
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
                            if (confirmed == true && context.mounted) {
                              final companion = await ref
                                  .read(taskNotifierProvider.notifier)
                                  .deleteTaskWithUndo(tc.task.id);
                              if (companion != null && context.mounted) {
                                AppFeedback.showUndoable(
                                  context,
                                  AppStrings.taskDeleted,
                                  onUndo: () {
                                    ref
                                        .read(taskNotifierProvider.notifier)
                                        .restoreTask(companion);
                                  },
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, __) => const TaskTileSkeleton(),
              ),
              error: (e, _) => ErrorState(
                onRetry: () => ref
                    .invalidate(categoryTasksStreamProvider(widget.categoryId)),
              ),
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
