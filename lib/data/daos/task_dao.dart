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

  Stream<List<TaskWithCategory>> watchTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.dueDate.isBetweenValues(startOfDay, endOfDay) |
          (tasks.dueDate.isSmallerThanValue(startOfDay) &
              tasks.isCompleted.equals(false)))
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
}
