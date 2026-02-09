import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/core/utils/icon_utils.dart';

void main() {
  group('IconUtils', () {
    test('getIcon returns correct icon for known names', () {
      expect(IconUtils.getIcon('work'), Icons.work);
      expect(IconUtils.getIcon('home'), Icons.home);
      expect(IconUtils.getIcon('school'), Icons.school);
      expect(IconUtils.getIcon('star'), Icons.star);
    });

    test('getIcon returns default category icon for unknown name', () {
      expect(IconUtils.getIcon('nonexistent'), Icons.category);
      expect(IconUtils.getIcon(''), Icons.category);
    });

    test('categoryIcons map contains expected entries', () {
      expect(IconUtils.categoryIcons.containsKey('work'), isTrue);
      expect(IconUtils.categoryIcons.containsKey('person'), isTrue);
      expect(IconUtils.categoryIcons.containsKey('code'), isTrue);
      expect(IconUtils.categoryIcons.containsKey('fitness_center'), isTrue);
    });

    test('categoryIcons map has 12 entries', () {
      expect(IconUtils.categoryIcons.length, 12);
    });
  });
}
