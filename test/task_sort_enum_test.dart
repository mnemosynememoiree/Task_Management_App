import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/models/enums/task_sort.dart';

void main() {
  group('TaskSort enum', () {
    test('has exactly 5 values', () {
      expect(TaskSort.values.length, 5);
    });

    test('contains all expected values', () {
      expect(TaskSort.values, contains(TaskSort.priorityAsc));
      expect(TaskSort.values, contains(TaskSort.dueDateAsc));
      expect(TaskSort.values, contains(TaskSort.dueDateDesc));
      expect(TaskSort.values, contains(TaskSort.titleAsc));
      expect(TaskSort.values, contains(TaskSort.createdAtDesc));
    });

    test('priorityAsc label is Priority', () {
      expect(TaskSort.priorityAsc.label, 'Priority');
    });

    test('date sort labels are descriptive', () {
      expect(TaskSort.dueDateAsc.label, 'Due date (earliest)');
      expect(TaskSort.dueDateDesc.label, 'Due date (latest)');
    });

    test('all labels are non-empty strings', () {
      for (final sort in TaskSort.values) {
        expect(sort.label, isNotEmpty);
      }
    });
  });
}
