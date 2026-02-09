import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    group('isToday', () {
      test('returns true for today', () {
        expect(AppDateUtils.isToday(DateTime.now()), isTrue);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(AppDateUtils.isToday(yesterday), isFalse);
      });

      test('returns false for null', () {
        expect(AppDateUtils.isToday(null), isFalse);
      });
    });

    group('isOverdue', () {
      test('returns true for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(AppDateUtils.isOverdue(yesterday), isTrue);
      });

      test('returns false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(AppDateUtils.isOverdue(tomorrow), isFalse);
      });

      test('returns false for null', () {
        expect(AppDateUtils.isOverdue(null), isFalse);
      });

      test('returns false for today', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        expect(AppDateUtils.isOverdue(today), isFalse);
      });
    });

    group('isUpcoming', () {
      test('returns true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(AppDateUtils.isUpcoming(tomorrow), isTrue);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(AppDateUtils.isUpcoming(yesterday), isFalse);
      });

      test('returns false for null', () {
        expect(AppDateUtils.isUpcoming(null), isFalse);
      });
    });

    group('formatDueDate', () {
      test('returns empty string for null', () {
        expect(AppDateUtils.formatDueDate(null), '');
      });

      test('returns Today for today', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        expect(AppDateUtils.formatDueDate(today), 'Today');
      });

      test('returns Tomorrow for tomorrow', () {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        expect(AppDateUtils.formatDueDate(tomorrow), 'Tomorrow');
      });

      test('returns Yesterday for yesterday', () {
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        expect(AppDateUtils.formatDueDate(yesterday), 'Yesterday');
      });
    });

    group('formatTime', () {
      test('returns empty string for null', () {
        expect(AppDateUtils.formatTime(null), '');
      });

      test('formats time correctly', () {
        final time = DateTime(2025, 1, 1, 14, 30);
        expect(AppDateUtils.formatTime(time), '2:30 PM');
      });

      test('formats morning time correctly', () {
        final time = DateTime(2025, 1, 1, 9, 5);
        expect(AppDateUtils.formatTime(time), '9:05 AM');
      });
    });
  });
}
