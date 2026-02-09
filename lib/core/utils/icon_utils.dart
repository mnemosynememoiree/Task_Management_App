import 'package:flutter/material.dart';

class IconUtils {
  IconUtils._();

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

  static IconData getIcon(String name) {
    return categoryIcons[name] ?? Icons.category;
  }
}
