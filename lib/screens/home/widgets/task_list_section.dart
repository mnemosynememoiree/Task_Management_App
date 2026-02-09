import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/feedback_utils.dart';
import '../../../data/daos/task_dao.dart';
import '../../../models/enums/task_filter.dart';
import '../../../providers/filter_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../widgets/animated_list_item.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../widgets/task_tile.dart';
import '../../../widgets/confirm_dialog.dart';

class TaskListSection extends ConsumerWidget {
  const TaskListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final filter = ref.watch(taskFilterProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState(context, filter);
          }
          return _buildTaskList(context, ref, tasks);
        },
        loading: () => _buildLoadingSkeleton(),
        error: (error, _) => ErrorState(
          onRetry: () => ref.invalidate(filteredTasksProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TaskFilter filter) {
    switch (filter) {
      case TaskFilter.overdue:
        return const EmptyState(
          icon: Icons.celebration_outlined,
          title: AppStrings.noOverdueTasks,
          subtitle: AppStrings.noOverdueSubtitle,
        );
      case TaskFilter.upcoming:
        return const EmptyState(
          icon: Icons.event_available_outlined,
          title: AppStrings.noUpcomingTasks,
          subtitle: AppStrings.noUpcomingSubtitle,
        );
      default:
        return EmptyState(
          title: AppStrings.noTasks,
          subtitle: AppStrings.noTasksSubtitle,
          actionLabel: AppStrings.createTask,
          onAction: () => context.push('/tasks/add'),
        );
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 140),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const TaskTileSkeleton(),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<TaskWithCategory> tasks,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(filteredTasksProvider);
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 140),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final tc = tasks[index];
          return AnimatedListItem(
            index: index,
            child: TaskTile(
              taskWithCategory: tc,
              index: index,
              onToggle: (value) {
                ref
                    .read(taskNotifierProvider.notifier)
                    .toggleCompletion(tc.task.id, value ?? false);
                if (value == true) {
                  AppFeedback.showSuccess(context, AppStrings.taskCompleted);
                } else {
                  AppFeedback.showSuccess(context, AppStrings.taskRestored);
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
  }
}
