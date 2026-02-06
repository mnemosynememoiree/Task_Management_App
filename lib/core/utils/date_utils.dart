import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDueDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today) &&
        dateOnly.isBefore(today.add(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  static String formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('h:mm a').format(time);
  }

  static String formatDateGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today — ${DateFormat('MMM d').format(date)}';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow — ${DateFormat('MMM d').format(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday — ${DateFormat('MMM d').format(date)}';
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('EEEE, MMM d, y').format(date);
    }
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dateOnly.isBefore(today);
  }

  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isUpcoming(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isAfter(today);
  }
}
