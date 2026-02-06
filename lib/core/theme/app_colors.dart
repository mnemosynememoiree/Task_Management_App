import 'package:flutter/material.dart';
import '../../models/enums/priority.dart';

class AppColors {
  AppColors._();

  // Primary palette - soft pastel lavender
  static const Color primary = Color(0xFF7C6FA0);
  static const Color primaryLight = Color(0xFFD8D0F0);

  // Backgrounds - warm cream/beige
  static const Color background = Color(0xFFFBF8F1);
  static const Color surface = Color(0xFFFFFFFF);

  // Text colors - dark navy
  static const Color onSurface = Color(0xFF2D3142);
  static const Color onSurfaceVariant = Color(0xFF8D99AE);

  // Borders - soft warm gray
  static const Color border = Color(0xFFE8E4DC);

  // Semantic colors
  static const Color error = Color(0xFFE88D8D);

  // Priority colors - pastel
  static const Color priorityHigh = Color(0xFFE88D8D);
  static const Color priorityMedium = Color(0xFFF5D98E);
  static const Color priorityLow = Color(0xFFA8B5C8);

  // Completed task - pastel mint
  static const Color completedTask = Color(0xFF7EC8A4);

  // Pastel task card backgrounds (alternating)
  static const List<Color> taskCardColors = [
    Color(0xFFFFF9DB), // pastel yellow
    Color(0xFFFFE5EC), // pastel pink
    Color(0xFFD5F5E3), // pastel mint
    Color(0xFFE8E0F0), // pastel lavender
    Color(0xFFFFEBD6), // pastel peach
    Color(0xFFD6F0F0), // pastel teal
  ];

  static Color colorForPriority(Priority priority) {
    switch (priority) {
      case Priority.high:
        return priorityHigh;
      case Priority.medium:
        return priorityMedium;
      case Priority.low:
        return priorityLow;
    }
  }

  // Category colors - pastel palette
  static const List<Color> categoryColors = [
    Color(0xFF9B8EC5), // pastel lavender
    Color(0xFFF2B5C8), // pastel rose
    Color(0xFF7EC8A4), // pastel mint
    Color(0xFFF5D98E), // pastel yellow
    Color(0xFFD4A5E5), // pastel purple
    Color(0xFFFFB8D0), // pastel pink
    Color(0xFF87CECC), // pastel teal
    Color(0xFFFFBE8A), // pastel peach
  ];
}
