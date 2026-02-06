import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/daos/task_dao.dart';
import '../data/daos/category_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final taskDaoProvider = Provider<TaskDao>((ref) {
  return ref.watch(databaseProvider).taskDao;
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return ref.watch(databaseProvider).categoryDao;
});
