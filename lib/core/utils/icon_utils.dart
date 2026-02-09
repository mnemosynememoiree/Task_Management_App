import 'package:flutter/material.dart';

/// Maps string icon names to Material [IconData] for category display.
class IconUtils {
  IconUtils._();

  /// Available category icon options keyed by name.
  static const Map<String, IconData> categoryIcons = {
    'category': Icons.category,
    'work': Icons.work,
    'person': Icons.person,
    'home': Icons.home,
    'school': Icons.school,
    'fitness_center': Icons.fitness_center,
    'shopping_cart': Icons.shopping_cart,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'code': Icons.code,
    'music_note': Icons.music_note,
    'restaurant': Icons.restaurant,
  };

  /// Returns the [IconData] for [name], or a default category icon if unknown.
  static IconData getIcon(String name) {
    return categoryIcons[name] ?? Icons.category;
  }
}
