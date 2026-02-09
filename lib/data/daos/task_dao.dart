import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../tables/task_table.dart';
import '../tables/category_table.dart';

part 'task_dao.g.dart';

class TaskWithCategory {
  final Task task;
  final Category category;

  TaskWithCategory({required this.task, required this.category});
}

@DriftAccessor(tables: [Tasks, Categories])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Stream<List<TaskWithCategory>> watchAllTasks() {
    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<List<TaskWithCategory>> watchTasksByFilter({
    required bool Function(Task) filter,
  }) {
    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows
          .map((row) {
            return TaskWithCategory(
              task: row.readTable(tasks),
              category: row.readTable(categories),
            );
          })
          .where((tc) => filter(tc.task))
          .toList();
    });
  }

  // Fixed: only show today's tasks, not overdue
  Stream<List<TaskWithCategory>> watchTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.dueDate.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<List<TaskWithCategory>> watchUpcomingTasks() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);

    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.dueDate.isBiggerOrEqualValue(endOfToday))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.dueDate),
        OrderingTerm.asc(tasks.priority),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<List<TaskWithCategory>> watchOverdueTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.dueDate.isSmallerThanValue(startOfDay) &
          tasks.isCompleted.equals(false))
      ..orderBy([
        OrderingTerm.asc(tasks.dueDate),
        OrderingTerm.asc(tasks.priority),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<List<TaskWithCategory>> watchTasksByCategory(int categoryId) {
    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.categoryId.equals(categoryId))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<int> watchTaskCountByCategory(int categoryId) {
    final query = select(tasks)
      ..where(
          (t) => t.categoryId.equals(categoryId) & t.isCompleted.equals(false));
    return query.watch().map((rows) => rows.length);
  }

  Future<Task> getTaskById(int id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  Future<bool> updateTask(TasksCompanion task) {
    return (update(tasks)..where((t) => t.id.equals(task.id.value)))
        .write(task)
        .then((rows) => rows > 0);
  }

  Future<void> toggleTaskCompletion(int id, bool isCompleted) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
      ),
    );
  }

  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> moveTasksToCategory(int fromCategoryId, int toCategoryId) {
    return (update(tasks)..where((t) => t.categoryId.equals(fromCategoryId)))
        .write(TasksCompanion(categoryId: Value(toCategoryId)));
  }

  // Search tasks by title/description
  Stream<List<TaskWithCategory>> watchSearchResults(String query) {
    final pattern = '%$query%';
    final q = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.title.like(pattern) | tasks.description.like(pattern))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return q.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  // Stats queries
  Stream<int> countTotal() {
    final q = select(tasks)..where((t) => t.isCompleted.equals(false));
    return q.watch().map((rows) => rows.length);
  }

  Stream<int> countCompletedToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final q = select(tasks)
      ..where((t) =>
          t.isCompleted.equals(true) &
          t.completedAt.isBetweenValues(startOfDay, endOfDay));
    return q.watch().map((rows) => rows.length);
  }

  Stream<int> countOverdue() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final q = select(tasks)
      ..where((t) =>
          t.dueDate.isSmallerThanValue(startOfDay) &
          t.isCompleted.equals(false));
    return q.watch().map((rows) => rows.length);
  }

  Stream<double> weeklyCompletionRate() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final allThisWeek = select(tasks)
      ..where((t) => t.createdAt.isBiggerOrEqualValue(weekAgo));
    return allThisWeek.watch().map((rows) {
      if (rows.isEmpty) return 0.0;
      final completed = rows.where((t) => t.isCompleted).length;
      return completed / rows.length;
    });
  }
}
