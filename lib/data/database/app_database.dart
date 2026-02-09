import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../tables/task_table.dart';
import '../tables/category_table.dart';
import '../daos/task_dao.dart';
import '../daos/category_dao.dart';

part 'app_database.g.dart';

/// Central Drift database that manages [Tasks] and [Categories] tables.
///
/// Accepts an optional [QueryExecutor] for testing (e.g. in-memory database).
/// Seeds default categories and sample tasks on first creation.
@DriftDatabase(tables: [Tasks, Categories], daos: [TaskDao, CategoryDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'todo_app_db');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future migrations here
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // Seed default data on first launch
        if (details.wasCreated) {
          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'General',
              icon: const Value('category'),
              colorValue: const Value(0xFF2563EB),
            ),
          );
          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Work',
              icon: const Value('work'),
              colorValue: const Value(0xFF8B5CF6),
            ),
          );
          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Personal',
              icon: const Value('person'),
              colorValue: const Value(0xFF10B981),
            ),
          );

          // Seed example tasks
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          await into(tasks).insert(
            TasksCompanion.insert(
              title: 'Welcome to Tasks! Tap me to edit',
              description: const Value(
                  'This is a sample task. You can edit or delete it.'),
              priority: const Value(1),
              dueDate: Value(today),
              categoryId: const Value(1),
            ),
          );
          await into(tasks).insert(
            TasksCompanion.insert(
              title: 'Try swiping left to delete',
              priority: const Value(2),
              dueDate: Value(today),
              categoryId: const Value(1),
            ),
          );
          await into(tasks).insert(
            TasksCompanion.insert(
              title: 'Swipe right to complete',
              priority: const Value(0),
              dueDate: Value(today.add(const Duration(days: 1))),
              categoryId: const Value(2),
            ),
          );
          await into(tasks).insert(
            TasksCompanion.insert(
              title: 'Plan team meeting',
              description: const Value('Discuss project timeline'),
              priority: const Value(0),
              dueDate: Value(today.add(const Duration(days: 2))),
              categoryId: const Value(2),
            ),
          );
          await into(tasks).insert(
            TasksCompanion.insert(
              title: 'Buy groceries',
              priority: const Value(1),
              dueDate: Value(today.add(const Duration(days: 3))),
              categoryId: const Value(3),
            ),
          );
        }
      },
    );
  }

  /// Deletes a category and reassigns its tasks in a single transaction.
  Future<void> deleteCategoryAndReassignTasks(
      int categoryId, int targetCategoryId) {
    return transaction(() async {
      await (update(tasks)..where((t) => t.categoryId.equals(categoryId)))
          .write(TasksCompanion(categoryId: Value(targetCategoryId)));
      await (delete(categories)..where((t) => t.id.equals(categoryId))).go();
    });
  }
}
