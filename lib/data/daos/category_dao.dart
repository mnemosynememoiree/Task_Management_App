import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../tables/category_table.dart';

part 'category_dao.g.dart';

/// Data access object for category CRUD operations.
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Watches all categories ordered by creation date.
  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Returns all categories as a one-shot future.
  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Retrieves a single category by its [id].
  Future<Category> getCategoryById(int id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Inserts a new category and returns the generated row ID.
  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// Updates an existing category and returns `true` if any row was affected.
  Future<bool> updateCategory(CategoriesCompanion category) {
    return (update(categories)
          ..where((t) => t.id.equals(category.id.value)))
        .write(category)
        .then((rows) => rows > 0);
  }

  /// Deletes a category by [id] and returns the number of rows removed.
  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  /// Creates a "General" category if the table is empty.
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

  /// Returns `true` if a category with [name] exists (case-insensitive).
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
