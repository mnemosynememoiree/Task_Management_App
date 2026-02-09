import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../tables/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<Category> getCategoryById(int id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(CategoriesCompanion category) {
    return (update(categories)
          ..where((t) => t.id.equals(category.id.value)))
        .write(category)
        .then((rows) => rows > 0);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  Future<void> ensureDefaultCategory() async {
    final count = await categories.count().getSingle();
    if (count == 0) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: 'General',
          icon: const Value('category'),
          colorValue: const Value(0xFF2563EB),
        ),
      );
    }
  }

  Future<bool> categoryNameExists(String name, {int? excludeId}) async {
    final query = select(categories)
      ..where((t) => t.name.lower().equals(name.toLowerCase()));
    final results = await query.get();
    if (excludeId != null) {
      return results.any((c) => c.id != excludeId);
    }
    return results.isNotEmpty;
  }
}
