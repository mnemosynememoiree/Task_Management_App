import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/services/voice_task_parser.dart';
import 'package:to_do_app/models/enums/priority.dart';

void main() {
  group('VoiceTaskParser', () {
    test('parses full sentence with all components', () {
      final result = VoiceTaskParser.parse(
        'Buy groceries tomorrow at 5pm high priority',
      );
      expect(result.title, 'Buy groceries');
      expect(result.priority, Priority.high);
      expect(result.dueTime?.hour, 17);
      expect(result.dueTime?.minute, 0);
      // Tomorrow should be today + 1
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(result.dueDate?.day, tomorrow.day);
      expect(result.dueDate?.month, tomorrow.month);
    });

    test('parses simple task with no extras', () {
      final result = VoiceTaskParser.parse('buy milk');
      expect(result.title, 'Buy milk');
      expect(result.dueDate, isNull);
      expect(result.dueTime, isNull);
      expect(result.priority, Priority.medium);
      expect(result.categoryName, isNull);
    });

    test('parses task with category matching', () {
      final result = VoiceTaskParser.parse(
        'meeting next monday at 2pm for work',
        categoryNames: ['Work', 'Personal', 'Shopping'],
      );
      expect(result.title, 'Meeting');
      expect(result.dueTime?.hour, 14);
      expect(result.dueTime?.minute, 0);
      expect(result.categoryName, 'Work');
      expect(result.dueDate, isNotNull);
    });

    test('parses urgent keyword as high priority', () {
      final result = VoiceTaskParser.parse('urgent call dentist today');
      expect(result.title, 'Call dentist');
      expect(result.priority, Priority.high);
      final today = DateTime.now();
      expect(result.dueDate?.day, today.day);
      expect(result.dueDate?.month, today.month);
    });

    test('parses low priority keywords', () {
      final result = VoiceTaskParser.parse('clean garage no rush');
      expect(result.title, 'Clean garage');
      expect(result.priority, Priority.low);
    });

    test('handles empty input', () {
      final result = VoiceTaskParser.parse('');
      expect(result.title, isEmpty);
    });

    test('handles whitespace-only input', () {
      final result = VoiceTaskParser.parse('   ');
      expect(result.title, isEmpty);
    });

    test('parses time with minutes', () {
      final result = VoiceTaskParser.parse('standup at 10:30 am');
      expect(result.title, 'Standup');
      expect(result.dueTime?.hour, 10);
      expect(result.dueTime?.minute, 30);
    });

    test('parses "in N days" date format', () {
      final result = VoiceTaskParser.parse('submit report in 3 days');
      expect(result.title, 'Submit report');
      final expected = DateTime.now().add(const Duration(days: 3));
      expect(result.dueDate?.day, expected.day);
      expect(result.dueDate?.month, expected.month);
    });

    test('parses "in" category with case-insensitive match', () {
      final result = VoiceTaskParser.parse(
        'buy milk in shopping',
        categoryNames: ['Shopping'],
      );
      expect(result.title, 'Buy milk');
      expect(result.categoryName, 'Shopping');
    });

    test('falls back to raw text when all tokens consumed', () {
      final result = VoiceTaskParser.parse('today high priority');
      // After extracting date and priority, title may be empty,
      // so it should fall back to cleaned raw input
      expect(result.title, isNotEmpty);
      expect(result.priority, Priority.high);
    });

    // --- Specific date tests ---

    test('parses "february 15" as a specific date', () {
      final result = VoiceTaskParser.parse('buy groceries february 15');
      expect(result.title, 'Buy groceries');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 15);
    });

    test('parses "feb 15" abbreviated month', () {
      final result = VoiceTaskParser.parse('buy groceries feb 15');
      expect(result.title, 'Buy groceries');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 15);
    });

    test('parses "march 3rd" with ordinal suffix', () {
      final result = VoiceTaskParser.parse('dentist appointment march 3rd');
      expect(result.title, 'Dentist appointment');
      expect(result.dueDate?.month, 3);
      expect(result.dueDate?.day, 3);
    });

    test('parses "on january 1st"', () {
      final result = VoiceTaskParser.parse('new years resolution on january 1st');
      expect(result.title, 'New years resolution');
      expect(result.dueDate?.month, 1);
      expect(result.dueDate?.day, 1);
    });

    test('parses "15 february" day-first format', () {
      final result = VoiceTaskParser.parse('buy groceries 15 february');
      expect(result.title, 'Buy groceries');
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 15);
    });

    // --- Standalone time tests (without "at") ---

    test('parses standalone "4am" without at', () {
      final result = VoiceTaskParser.parse('wake up 4am');
      expect(result.title, 'Wake up');
      expect(result.dueTime?.hour, 4);
      expect(result.dueTime?.minute, 0);
    });

    test('parses standalone "7:00 pm" without at', () {
      final result = VoiceTaskParser.parse('dinner 7:00 pm');
      expect(result.title, 'Dinner');
      expect(result.dueTime?.hour, 19);
      expect(result.dueTime?.minute, 0);
    });

    // --- Speech artifact tests ---

    test('normalizes "p.m." speech artifact to pm', () {
      final result = VoiceTaskParser.parse('buy groceries 7:00 p.m.');
      expect(result.title, 'Buy groceries');
      expect(result.dueTime?.hour, 19);
      expect(result.dueTime?.minute, 0);
    });

    test('parses full sentence: "buy groceries february 15 7:00 p.m."', () {
      final result = VoiceTaskParser.parse(
        'buy groceries and february 15 7:00 p.m.',
      );
      expect(result.title, 'Buy groceries');
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 15);
      expect(result.dueTime?.hour, 19);
      expect(result.dueTime?.minute, 0);
    });

    test('parses "buy groceries february 15 at 4am"', () {
      final result = VoiceTaskParser.parse(
        'buy groceries february 15 at 4am',
      );
      expect(result.title, 'Buy groceries');
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 15);
      expect(result.dueTime?.hour, 4);
      expect(result.dueTime?.minute, 0);
    });

    test('combines specific date + time + priority + category', () {
      final result = VoiceTaskParser.parse(
        'submit report march 20 at 9am high priority for work',
        categoryNames: ['Work', 'Personal'],
      );
      expect(result.title, 'Submit report');
      expect(result.dueDate?.month, 3);
      expect(result.dueDate?.day, 20);
      expect(result.dueTime?.hour, 9);
      expect(result.priority, Priority.high);
      expect(result.categoryName, 'Work');
    });

    // --- Year date tests ---

    test('parses "feb 12 2026" with explicit year', () {
      final result = VoiceTaskParser.parse('meeting feb 12 2026');
      expect(result.title, 'Meeting');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate?.year, 2026);
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 12);
    });

    test('parses "12 february 2026" day-first with explicit year', () {
      final result = VoiceTaskParser.parse('meeting 12 february 2026');
      expect(result.title, 'Meeting');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate?.year, 2026);
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 12);
    });

    test('parses "march 3rd 2027" with ordinal and explicit year', () {
      final result = VoiceTaskParser.parse('dentist march 3rd 2027');
      expect(result.title, 'Dentist');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate?.year, 2027);
      expect(result.dueDate?.month, 3);
      expect(result.dueDate?.day, 3);
    });

    test('no-year dates still auto-increment correctly', () {
      final result = VoiceTaskParser.parse('buy groceries february 15');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 15);
      // Year should be current or next depending on whether date has passed
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final candidate = DateTime(now.year, 2, 15);
      final expectedYear = candidate.isBefore(today) ? now.year + 1 : now.year;
      expect(result.dueDate?.year, expectedYear);
    });

    // --- Reversed priority tests ---

    test('parses "priority high" reversed word order', () {
      final result = VoiceTaskParser.parse('call dentist priority high');
      expect(result.title, 'Call dentist');
      expect(result.priority, Priority.high);
    });

    test('parses "priority low" reversed word order', () {
      final result = VoiceTaskParser.parse('clean garage priority low');
      expect(result.title, 'Clean garage');
      expect(result.priority, Priority.low);
    });

    test('parses "priority medium" reversed word order', () {
      final result = VoiceTaskParser.parse('send email priority medium');
      expect(result.title, 'Send email');
      expect(result.priority, Priority.medium);
    });

    // --- Trailing standalone priority tests ---

    test('parses trailing "high" as priority', () {
      final result = VoiceTaskParser.parse('call dentist high');
      expect(result.title, 'Call dentist');
      expect(result.priority, Priority.high);
    });

    test('parses trailing "low" as priority', () {
      final result = VoiceTaskParser.parse('water plants low');
      expect(result.title, 'Water plants');
      expect(result.priority, Priority.low);
    });

    test('does not match mid-sentence "high"', () {
      final result = VoiceTaskParser.parse('buy high chairs for kids');
      // "high" is mid-sentence, should NOT be matched as priority
      expect(result.priority, Priority.medium);
    });

    // --- "And" preservation tests ---

    test('preserves "and" in "buy bread and butter"', () {
      final result = VoiceTaskParser.parse('buy bread and butter');
      expect(result.title, 'Buy bread and butter');
    });

    test('preserves "and" with date extraction', () {
      final result = VoiceTaskParser.parse('buy bread and butter tomorrow');
      expect(result.title, 'Buy bread and butter');
      expect(result.dueDate, isNotNull);
    });

    test('strips trailing "and" after time extraction', () {
      final result = VoiceTaskParser.parse('buy groceries and at 5pm');
      // After time extraction, "and" is trailing → stripped
      expect(result.title.toLowerCase().contains('and'), isFalse);
      expect(result.dueTime?.hour, 17);
    });

    // --- Noon / midnight tests ---

    test('parses "at noon" as 12:00', () {
      final result = VoiceTaskParser.parse('lunch meeting at noon');
      expect(result.title, 'Lunch meeting');
      expect(result.dueTime, isNotNull);
      expect(result.dueTime?.hour, 12);
      expect(result.dueTime?.minute, 0);
    });

    test('parses "noon" without "at" as 12:00', () {
      final result = VoiceTaskParser.parse('lunch meeting noon');
      expect(result.title, 'Lunch meeting');
      expect(result.dueTime, isNotNull);
      expect(result.dueTime?.hour, 12);
      expect(result.dueTime?.minute, 0);
    });

    test('parses "at midnight" as 0:00', () {
      final result = VoiceTaskParser.parse('deploy release at midnight');
      expect(result.title, 'Deploy release');
      expect(result.dueTime, isNotNull);
      expect(result.dueTime?.hour, 0);
      expect(result.dueTime?.minute, 0);
    });

    test('parses "midnight" without "at" as 0:00', () {
      final result = VoiceTaskParser.parse('deploy release midnight');
      expect(result.title, 'Deploy release');
      expect(result.dueTime, isNotNull);
      expect(result.dueTime?.hour, 0);
      expect(result.dueTime?.minute, 0);
    });

    // --- Full integration test ---

    test('parses all fields: date with year, noon, priority, category', () {
      final result = VoiceTaskParser.parse(
        'submit report feb 12 2026 at noon priority high for work',
        categoryNames: ['Work', 'Personal'],
      );
      expect(result.title, 'Submit report');
      expect(result.dueDate?.year, 2026);
      expect(result.dueDate?.month, 2);
      expect(result.dueDate?.day, 12);
      expect(result.dueTime?.hour, 12);
      expect(result.dueTime?.minute, 0);
      expect(result.priority, Priority.high);
      expect(result.categoryName, 'Work');
    });
  });
}
