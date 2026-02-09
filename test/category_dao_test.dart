import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/data/database/app_database.dart';
import 'package:to_do_app/data/daos/category_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryDao categoryDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    categoryDao = db.categoryDao;

    // Clear seeded data from the migration so tests start clean.
    await db.delete(db.tasks).go();
    await db.delete(db.categories).go();
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDao', () {
    test('insertCategory and getCategoryById returns correct category', () async {
      final id = await categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: 'Test',
          icon: const Value('star'),
          colorValue: const Value(0xFF000000),
        ),
      );

      final category = await categoryDao.getCategoryById(id);
      expect(category.name, 'Test');
      expect(category.icon, 'star');
      expect(category.colorValue, 0xFF000000);
    });

    test('updateCategory modifies fields', () async {
      final id = await categoryDao.insertCategory(
        CategoriesCompanion.insert(name: 'Original'),
      );

      await categoryDao.updateCategory(CategoriesCompanion(
        id: Value(id),
        name: const Value('Updated'),
        icon: const Value('work'),
      ));

      final category = await categoryDao.getCategoryById(id);
      expect(category.name, 'Updated');
      expect(category.icon, 'work');
    });

    test('deleteCategory removes category', () async {
      final id = await categoryDao.insertCategory(
        CategoriesCompanion.insert(name: 'To delete'),
      );
      final deleted = await categoryDao.deleteCategory(id);

      expect(deleted, 1);
      expect(
        () => categoryDao.getCategoryById(id),
        throwsA(isA<StateError>()),
      );
    });

    test('getAllCategories returns all inserted categories', () async {
      await categoryDao.insertCategory(CategoriesCompanion.insert(name: 'Cat A'));
      await categoryDao.insertCategory(CategoriesCompanion.insert(name: 'Cat B'));
      await categoryDao.insertCategory(CategoriesCompanion.insert(name: 'Cat C'));

      final all = await categoryDao.getAllCategories();
      expect(all.length, 3);
    });

    test('ensureDefaultCategory creates General if no categories exist', () async {
      await categoryDao.ensureDefaultCategory();

      final all = await categoryDao.getAllCategories();
      expect(all.length, 1);
      expect(all.first.name, 'General');
    });

    test('ensureDefaultCategory does nothing if categories exist', () async {
      await categoryDao.insertCategory(CategoriesCompanion.insert(name: 'Existing'));
      await categoryDao.ensureDefaultCategory();

      final all = await categoryDao.getAllCategories();
      expect(all.length, 1);
      expect(all.first.name, 'Existing');
    });

    test('categoryNameExists returns true for existing name', () async {
      await categoryDao.insertCategory(CategoriesCompanion.insert(name: 'Work'));

      final exists = await categoryDao.categoryNameExists('Work');
      expect(exists, isTrue);
    });

    test('categoryNameExists returns false for non-existing name', () async {
      final exists = await categoryDao.categoryNameExists('NonExistent');
      expect(exists, isFalse);
    });

    test('categoryNameExists is case-insensitive', () async {
      await categoryDao.insertCategory(CategoriesCompanion.insert(name: 'Work'));

      expect(await categoryDao.categoryNameExists('work'), isTrue);
      expect(await categoryDao.categoryNameExists('WORK'), isTrue);
    });

    test('categoryNameExists excludes given id', () async {
      final id = await categoryDao.insertCategory(
        CategoriesCompanion.insert(name: 'Work'),
      );

      // Excluding its own ID should return false.
      final exists = await categoryDao.categoryNameExists('Work', excludeId: id);
      expect(exists, isFalse);
    });
  });
}
