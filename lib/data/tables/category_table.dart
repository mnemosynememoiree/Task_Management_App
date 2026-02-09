import 'package:drift/drift.dart';

/// Drift table definition for task categories.
///
/// Each category has a [name], an [icon] identifier, and a [colorValue]
/// stored as an ARGB integer.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text().withDefault(const Constant('category'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF2563EB))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
