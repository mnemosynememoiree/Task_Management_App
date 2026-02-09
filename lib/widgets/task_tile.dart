import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/utils/date_utils.dart';
import '../data/daos/task_dao.dart';
import '../data/database/app_database.dart';
import '../models/enums/priority.dart';
import 'priority_indicator.dart';

class TaskTile extends StatelessWidget {
  final TaskWithCategory taskWithCategory;
  final ValueChanged<bool?>? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int index;

  const TaskTile({
    super.key,
    required this.taskWithCategory,
    this.onToggle,
    this.onTap,
    this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final task = taskWithCategory.task;
    final category = taskWithCategory.category;
    final priority = Priority.fromValue(task.priority);
    final isOverdue =
        !task.isCompleted && AppDateUtils.isOverdue(task.dueDate);

    return Slidable(
      key: ValueKey(task.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.selectionClick();
              onToggle?.call(!task.isCompleted);
            },
            backgroundColor: task.isCompleted
                ? AppColors.warning
                : AppColors.completedTask,
            foregroundColor: Colors.white,
            icon: task.isCompleted
                ? Icons.undo
                : Icons.check,
            label: task.isCompleted ? 'Undo' : 'Complete',
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              onDelete?.call();
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(14),
            ),
          ),
        ],
      ),
      child: Opacity(
        opacity: task.isCompleted ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.sm,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _buildCheckbox(context, task),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PriorityIndicator(priority: priority),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? AppColors.onSurfaceVariant
                                          : AppColors.onSurface,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (task.dueDate != null) ...[
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppDateUtils.formatDueDate(task.dueDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isOverdue
                                          ? AppColors.error
                                          : AppColors.onSurfaceVariant,
                                    ),
                              ),
                              if (task.dueTime != null) ...[
                                Text(
                                  ' ${AppDateUtils.formatTime(task.dueTime)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isOverdue
                                            ? AppColors.error
                                            : AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                              const SizedBox(width: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(category.colorValue)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Color(category.colorValue),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context, Task task) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: task.isCompleted,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          onToggle?.call(value);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        activeColor: AppColors.completedTask,
        side: BorderSide(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
    );
  }
}
