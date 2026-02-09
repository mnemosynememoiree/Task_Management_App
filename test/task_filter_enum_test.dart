import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/models/enums/task_filter.dart';

void main() {
  group('TaskFilter enum', () {
    test('has exactly 4 values', () {
      expect(TaskFilter.values.length, 4);
    });

    test('contains all expected values', () {
      expect(TaskFilter.values, contains(TaskFilter.today));
      expect(TaskFilter.values, contains(TaskFilter.upcoming));
      expect(TaskFilter.values, contains(TaskFilter.overdue));
      expect(TaskFilter.values, contains(TaskFilter.all));
    });

    test('each filter has correct label', () {
      expect(TaskFilter.today.label, 'Today');
      expect(TaskFilter.upcoming.label, 'Upcoming');
      expect(TaskFilter.overdue.label, 'Overdue');
      expect(TaskFilter.all.label, 'All');
    });

    test('labels are non-empty strings', () {
      for (final filter in TaskFilter.values) {
        expect(filter.label, isNotEmpty);
      }
    });
  });
}
