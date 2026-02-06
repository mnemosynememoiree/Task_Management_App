import 'package:drift/drift.dart';
import 'category_table.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get dueTime => dateTime().nullable()();
  IntColumn get categoryId =>
      integer().references(Categories, #id).withDefault(const Constant(1))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
