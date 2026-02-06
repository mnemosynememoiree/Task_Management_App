import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/enums/priority.dart';

class PrioritySelector extends StatelessWidget {
  final Priority selected;
  final ValueChanged<Priority> onChanged;

  const PrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Priority.values.map((priority) {
        final isSelected = priority == selected;
        final color = AppColors.colorForPriority(priority);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(priority.label),
            selected: isSelected,
            onSelected: (_) => onChanged(priority),
            backgroundColor: AppColors.surface,
            selectedColor: color.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected ? color.withValues(alpha: 0.5) : AppColors.border,
            ),
            showCheckmark: false,
            avatar: isSelected
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
