import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/daos/category_dao.dart';
import 'database_provider.dart';

final categoriesStreamProvider =
    StreamProvider<List<Category>>((ref) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.watchAllCategories();
});

final categoryByIdProvider =
    FutureProvider.family<Category, int>((ref, id) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.getCategoryById(id);
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryDao _dao;
  final AppDatabase _db;

  CategoryNotifier(this._dao, this._db) : super(const AsyncValue.data(null));

  Future<int> addCategory({
    required String name,
    String icon = 'category',
    int colorValue = 0xFF2563EB,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await _dao.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          icon: Value(icon),
          colorValue: Value(colorValue),
        ),
      );
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String icon,
    required int colorValue,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dao.updateCategory(
        CategoriesCompanion(
          id: Value(id),
          name: Value(name),
          icon: Value(icon),
          colorValue: Value(colorValue),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncValue.loading();
    try {
      await _dao.deleteCategory(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Transactional delete: moves tasks to target category then deletes.
  Future<void> deleteCategoryAndReassignTasks(
      int categoryId, int targetCategoryId) async {
    state = const AsyncValue.loading();
    try {
      await _db.deleteCategoryAndReassignTasks(categoryId, targetCategoryId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> categoryNameExists(String name, {int? excludeId}) {
    return _dao.categoryNameExists(name, excludeId: excludeId);
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier(
    ref.watch(categoryDaoProvider),
    ref.watch(databaseProvider),
  );
});
