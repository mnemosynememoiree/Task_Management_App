import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/daos/task_dao.dart';
import '../../../models/enums/task_filter.dart';
import '../../../providers/filter_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../widgets/empty_state.dart';
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
            return _buildEmptyState(filter);
          }
          return _buildTaskList(context, ref, tasks);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState(TaskFilter filter) {
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
        return const EmptyState(
          title: AppStrings.noTasks,
          subtitle: AppStrings.noTasksSubtitle,
        );
    }
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<TaskWithCategory> tasks,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tc = tasks[index];
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
              ref.read(taskNotifierProvider.notifier).deleteTask(tc.task.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.taskDeleted)),
                );
              }
            }
          },
        );
      },
    );
  }
}
