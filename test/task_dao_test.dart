import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/data/database/app_database.dart';
import 'package:to_do_app/data/daos/task_dao.dart';

void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late int defaultCategoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    taskDao = db.taskDao;

    // Clear seeded tasks so tests start clean.
    // Keep seeded categories but clear tasks.
    await db.delete(db.tasks).go();

    // Get the first seeded category ID for use as default.
    final categories = await db.categoryDao.getAllCategories();
    defaultCategoryId = categories.first.id;
  });

  tearDown(() async {
    await db.close();
  });

  TasksCompanion makeTask({
    required String title,
    int priority = 1,
    DateTime? dueDate,
    int? categoryId,
    bool isCompleted = false,
  }) {
    return TasksCompanion.insert(
      title: title,
      priority: Value(priority),
      dueDate: Value(dueDate),
      categoryId: Value(categoryId ?? defaultCategoryId),
      isCompleted: Value(isCompleted),
    );
  }

  group('TaskDao', () {
    test('insertTask and getTaskById returns correct task', () async {
      final id = await taskDao.insertTask(makeTask(title: 'Test task'));
      final task = await taskDao.getTaskById(id);

      expect(task.title, 'Test task');
      expect(task.priority, 1);
      expect(task.isCompleted, false);
    });

    test('updateTask modifies task fields', () async {
      final id = await taskDao.insertTask(makeTask(title: 'Original'));
      await taskDao.updateTask(TasksCompanion(
        id: Value(id),
        title: const Value('Updated'),
        priority: const Value(0),
      ));

      final task = await taskDao.getTaskById(id);
      expect(task.title, 'Updated');
      expect(task.priority, 0);
    });

    test('deleteTask removes task', () async {
      final id = await taskDao.insertTask(makeTask(title: 'To delete'));
      final deleted = await taskDao.deleteTask(id);

      expect(deleted, 1);
      expect(
        () => taskDao.getTaskById(id),
        throwsA(isA<StateError>()),
      );
    });

    test('toggleTaskCompletion sets isCompleted and completedAt', () async {
      final id = await taskDao.insertTask(makeTask(title: 'Toggle me'));

      await taskDao.toggleTaskCompletion(id, true);
      var task = await taskDao.getTaskById(id);
      expect(task.isCompleted, true);
      expect(task.completedAt, isNotNull);

      await taskDao.toggleTaskCompletion(id, false);
      task = await taskDao.getTaskById(id);
      expect(task.isCompleted, false);
      expect(task.completedAt, isNull);
    });

    test('watchTodayTasks returns only tasks due today', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final tomorrow = today.add(const Duration(days: 1));

      await taskDao.insertTask(makeTask(title: 'Today task', dueDate: today));
      await taskDao.insertTask(makeTask(title: 'Tomorrow task', dueDate: tomorrow));

      final tasks = await taskDao.watchTodayTasks().first;
      expect(tasks.length, 1);
      expect(tasks.first.task.title, 'Today task');
    });

    test('watchOverdueTasks returns only past-due incomplete tasks', () async {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final today = DateTime(now.year, now.month, now.day, 12);

      await taskDao.insertTask(makeTask(title: 'Overdue task', dueDate: yesterday));
      await taskDao.insertTask(makeTask(title: 'Today task', dueDate: today));
      await taskDao.insertTask(
        makeTask(title: 'Completed overdue', dueDate: yesterday, isCompleted: true),
      );

      final tasks = await taskDao.watchOverdueTasks().first;
      expect(tasks.length, 1);
      expect(tasks.first.task.title, 'Overdue task');
    });

    test('watchUpcomingTasks returns only future tasks', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 12);

      await taskDao.insertTask(makeTask(title: 'Today task', dueDate: today));
      await taskDao.insertTask(makeTask(title: 'Upcoming task', dueDate: tomorrow));

      final tasks = await taskDao.watchUpcomingTasks().first;
      expect(tasks.length, 1);
      expect(tasks.first.task.title, 'Upcoming task');
    });

    test('watchSearchResults matches title pattern', () async {
      await taskDao.insertTask(makeTask(title: 'Buy groceries'));
      await taskDao.insertTask(makeTask(title: 'Read a book'));
      await taskDao.insertTask(makeTask(title: 'Buy flowers'));

      final results = await taskDao.watchSearchResults('Buy').first;
      expect(results.length, 2);
      expect(results.map((r) => r.task.title), containsAll(['Buy groceries', 'Buy flowers']));
    });

    test('countTotal returns number of incomplete tasks', () async {
      await taskDao.insertTask(makeTask(title: 'Task 1'));
      await taskDao.insertTask(makeTask(title: 'Task 2'));
      await taskDao.insertTask(makeTask(title: 'Done task', isCompleted: true));

      final count = await taskDao.countTotal().first;
      expect(count, 2);
    });

    test('moveTasksToCategory reassigns category', () async {
      final categories = await db.categoryDao.getAllCategories();
      final fromId = categories[0].id;
      final toId = categories[1].id;

      final id = await taskDao.insertTask(makeTask(title: 'Move me', categoryId: fromId));
      await taskDao.moveTasksToCategory(fromId, toId);

      final task = await taskDao.getTaskById(id);
      expect(task.categoryId, toId);
    });

    test('watchAllTasks returns tasks with categories', () async {
      await taskDao.insertTask(makeTask(title: 'Task with category'));

      final tasks = await taskDao.watchAllTasks().first;
      expect(tasks.length, 1);
      expect(tasks.first.task.title, 'Task with category');
      expect(tasks.first.category.name, 'General');
    });

    test('watchTasksByCategory filters by category id', () async {
      final categories = await db.categoryDao.getAllCategories();
      final generalId = categories[0].id;
      final workId = categories[1].id;

      await taskDao.insertTask(makeTask(title: 'General task', categoryId: generalId));
      await taskDao.insertTask(makeTask(title: 'Work task', categoryId: workId));

      final tasks = await taskDao.watchTasksByCategory(workId).first;
      expect(tasks.length, 1);
      expect(tasks.first.task.title, 'Work task');
    });
  });
}
