import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/enums/priority.dart';

class PriorityIndicator extends StatelessWidget {
  final Priority priority;
  final double size;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.colorForPriority(priority),
        shape: BoxShape.circle,
      ),
    );
  }
}
