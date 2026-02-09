import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/models/enums/priority.dart';

void main() {
  group('Priority enum', () {
    test('fromValue(0) returns high', () {
      expect(Priority.fromValue(0), Priority.high);
    });

    test('fromValue(1) returns medium', () {
      expect(Priority.fromValue(1), Priority.medium);
    });

    test('fromValue(2) returns low', () {
      expect(Priority.fromValue(2), Priority.low);
    });

    test('invalid value defaults to medium', () {
      expect(Priority.fromValue(99), Priority.medium);
      expect(Priority.fromValue(-1), Priority.medium);
    });

    test('.value getter returns correct int', () {
      expect(Priority.high.value, 0);
      expect(Priority.medium.value, 1);
      expect(Priority.low.value, 2);
    });

    test('.label getter returns correct string', () {
      expect(Priority.high.label, 'High');
      expect(Priority.medium.label, 'Medium');
      expect(Priority.low.label, 'Low');
    });
  });
}
