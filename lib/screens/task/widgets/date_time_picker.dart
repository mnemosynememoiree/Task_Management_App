import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';

class DateTimePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<DateTime?> onTimeChanged;

  const DateTimePicker({
    super.key,
    this.selectedDate,
    this.selectedTime,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateChip(context),
        if (selectedDate != null) ...[
          const SizedBox(height: 8),
          _buildTimeChip(context),
        ],
      ],
    );
  }

  Widget _buildDateChip(BuildContext context) {
    final hasDate = selectedDate != null;

    return Row(
      children: [
        ActionChip(
          avatar: Icon(
            Icons.calendar_today,
            size: 16,
            color: hasDate ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          label: Text(
            hasDate
                ? AppDateUtils.formatDueDate(selectedDate)
                : 'Add due date',
          ),
          labelStyle: TextStyle(
            color: hasDate ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          side: BorderSide(
            color: hasDate ? AppColors.primary : AppColors.border,
          ),
          onPressed: () => _pickDate(context),
        ),
        if (hasDate) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              onDateChanged(null);
              onTimeChanged(null);
            },
            visualDensity: VisualDensity.compact,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Widget _buildTimeChip(BuildContext context) {
    final hasTime = selectedTime != null;

    return Row(
      children: [
        ActionChip(
          avatar: Icon(
            Icons.access_time,
            size: 16,
            color: hasTime ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          label: Text(
            hasTime
                ? AppDateUtils.formatTime(selectedTime)
                : 'Add time',
          ),
          labelStyle: TextStyle(
            color: hasTime ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          side: BorderSide(
            color: hasTime ? AppColors.primary : AppColors.border,
          ),
          onPressed: () => _pickTime(context),
        ),
        if (hasTime) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => onTimeChanged(null),
            visualDensity: VisualDensity.compact,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final initial = selectedTime != null
        ? TimeOfDay.fromDateTime(selectedTime!)
        : TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final dt = DateTime(2000, 1, 1, picked.hour, picked.minute);
      onTimeChanged(dt);
    }
  }
}
