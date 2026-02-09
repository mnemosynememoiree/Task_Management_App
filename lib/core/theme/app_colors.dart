import 'package:flutter/material.dart';
import '../../models/enums/priority.dart';

class AppColors {
  AppColors._();

  // Primary palette - deep indigo
  static const Color primary = Color(0xFF4A56E2);
  static const Color primaryLight = Color(0xFFEAECFB);

  // Backgrounds - cool neutral gray
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F2);

  // Text colors - near-black with blue undertone
  static const Color onSurface = Color(0xFF1A1C2B);
  static const Color onSurfaceVariant = Color(0xFF6E7191);

  // Borders - cool neutral
  static const Color border = Color(0xFFE4E4E8);

  // Semantic colors
  static const Color error = Color(0xFFE5484D);
  static const Color success = Color(0xFF30A46C);
  static const Color warning = Color(0xFFF5A623);

  // Priority colors - saturated
  static const Color priorityHigh = Color(0xFFE5484D);
  static const Color priorityMedium = Color(0xFFF5A623);
  static const Color priorityLow = Color(0xFF889BB0);

  // Completed task - rich green
  static const Color completedTask = Color(0xFF30A46C);

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

  // Category colors - richer tones
  static const List<Color> categoryColors = [
    Color(0xFF5B5FC7), // indigo
    Color(0xFFE5484D), // rose
    Color(0xFF30A46C), // green
    Color(0xFFF5A623), // amber
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFFF97316), // orange
  ];
}
