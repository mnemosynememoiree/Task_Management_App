import '../../models/enums/priority.dart';

/// Holds the structured result of parsing a voice input string.
class ParsedVoiceTask {
  final String title;
  final DateTime? dueDate;
  final DateTime? dueTime;
  final Priority priority;
  final String? categoryName;

  const ParsedVoiceTask({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.priority = Priority.medium,
    this.categoryName,
  });
}

/// Parses natural-language voice input into a structured [ParsedVoiceTask].
///
/// Extracts priority, date, time, and category from free-form speech text.
class VoiceTaskParser {
  VoiceTaskParser._();

  static const _monthNames = {
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  static final _monthPattern = _monthNames.keys.join('|');

  /// Parses [input] text and returns a [ParsedVoiceTask] with extracted fields.
  static ParsedVoiceTask parse(String input, {List<String> categoryNames = const []}) {
    if (input.trim().isEmpty) {
      return const ParsedVoiceTask(title: '');
    }

    String text = input.trim();
    Priority priority = Priority.medium;
    DateTime? dueDate;
    DateTime? dueTime;
    String? categoryName;

    // 1. Extract priority
    final priorityResult = _extractPriority(text);
    text = priorityResult.$1;
    priority = priorityResult.$2;

    // 2. Extract date
    final dateResult = _extractDate(text);
    text = dateResult.$1;
    dueDate = dateResult.$2;

    // 3. Extract time
    final timeResult = _extractTime(text);
    text = timeResult.$1;
    dueTime = timeResult.$2;

    // 4. Extract category
    final categoryResult = _extractCategory(text, categoryNames);
    text = categoryResult.$1;
    categoryName = categoryResult.$2;

    // 5. Clean title
    final title = _cleanTitle(text);

    return ParsedVoiceTask(
      title: title.isEmpty ? _cleanTitle(input) : title,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      categoryName: categoryName,
    );
  }

  static (String, Priority) _extractPriority(String text) {
    final patterns = <RegExp, Priority>{
      RegExp(r'\b(high\s+priority|priority\s+high|urgent|important)\b', caseSensitive: false): Priority.high,
      RegExp(r'\b(low\s+priority|priority\s+low|no\s+rush|not\s+urgent)\b', caseSensitive: false): Priority.low,
      RegExp(r'\b(medium\s+priority|priority\s+medium|normal\s+priority)\b', caseSensitive: false): Priority.medium,
    };

    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(text);
      if (match != null) {
        text = text.replaceFirst(entry.key, ' ');
        return (text, entry.value);
      }
    }

    // Second pass: trailing standalone "high" or "low" at end of sentence
    final trailingPriorityRegex = RegExp(r'\b(high|low)\s*$', caseSensitive: false);
    final trailingMatch = trailingPriorityRegex.firstMatch(text);
    if (trailingMatch != null) {
      final word = trailingMatch.group(1)!.toLowerCase();
      text = text.replaceFirst(trailingPriorityRegex, ' ');
      return (text, word == 'high' ? Priority.high : Priority.low);
    }

    return (text, Priority.medium);
  }

  static (String, DateTime?) _extractDate(String text) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // "today"
    final todayRegex = RegExp(r'\btoday\b', caseSensitive: false);
    if (todayRegex.hasMatch(text)) {
      text = text.replaceFirst(todayRegex, ' ');
      return (text, today);
    }

    // "tomorrow"
    final tomorrowRegex = RegExp(r'\btomorrow\b', caseSensitive: false);
    if (tomorrowRegex.hasMatch(text)) {
      text = text.replaceFirst(tomorrowRegex, ' ');
      return (text, today.add(const Duration(days: 1)));
    }

    // "in N days"
    final inDaysRegex = RegExp(r'\bin\s+(\d+)\s+days?\b', caseSensitive: false);
    final inDaysMatch = inDaysRegex.firstMatch(text);
    if (inDaysMatch != null) {
      final days = int.parse(inDaysMatch.group(1)!);
      text = text.replaceFirst(inDaysRegex, ' ');
      return (text, today.add(Duration(days: days)));
    }

    // Specific date: "february 15", "feb 15", "march 3rd", "jan 1st", "feb 12 2026"
    // Also handles: "on february 15", "on feb 15"
    final specificDateRegex = RegExp(
      '\\b(?:on\\s+)?($_monthPattern)\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:\\s+(\\d{4}))?\\b',
      caseSensitive: false,
    );
    final specificDateMatch = specificDateRegex.firstMatch(text);
    if (specificDateMatch != null) {
      final monthStr = specificDateMatch.group(1)!.toLowerCase();
      final day = int.parse(specificDateMatch.group(2)!);
      final month = _monthNames[monthStr]!;
      if (day >= 1 && day <= 31) {
        int year;
        final yearStr = specificDateMatch.group(3);
        if (yearStr != null) {
          year = int.parse(yearStr);
        } else {
          year = now.year;
          // If the date has already passed this year, use next year
          final candidate = DateTime(year, month, day);
          if (candidate.isBefore(today)) {
            year++;
          }
        }
        text = text.replaceFirst(specificDateRegex, ' ');
        return (text, DateTime(year, month, day));
      }
    }

    // Specific date: "15 february", "15 feb", "3rd march", "12 february 2026"
    final specificDateAltRegex = RegExp(
      '\\b(?:on\\s+)?(\\d{1,2})(?:st|nd|rd|th)?\\s+($_monthPattern)(?:\\s+(\\d{4}))?\\b',
      caseSensitive: false,
    );
    final specificDateAltMatch = specificDateAltRegex.firstMatch(text);
    if (specificDateAltMatch != null) {
      final day = int.parse(specificDateAltMatch.group(1)!);
      final monthStr = specificDateAltMatch.group(2)!.toLowerCase();
      final month = _monthNames[monthStr]!;
      if (day >= 1 && day <= 31) {
        int year;
        final yearStr = specificDateAltMatch.group(3);
        if (yearStr != null) {
          year = int.parse(yearStr);
        } else {
          year = now.year;
          final candidate = DateTime(year, month, day);
          if (candidate.isBefore(today)) {
            year++;
          }
        }
        text = text.replaceFirst(specificDateAltRegex, ' ');
        return (text, DateTime(year, month, day));
      }
    }

    // "next monday", "next tuesday", etc.
    final nextDayRegex = RegExp(
      r'\bnext\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      caseSensitive: false,
    );
    final nextDayMatch = nextDayRegex.firstMatch(text);
    if (nextDayMatch != null) {
      final dayName = nextDayMatch.group(1)!.toLowerCase();
      final targetDay = _dayOfWeek(dayName);
      var daysUntil = targetDay - now.weekday;
      if (daysUntil <= 0) daysUntil += 7;
      text = text.replaceFirst(nextDayRegex, ' ');
      return (text, today.add(Duration(days: daysUntil)));
    }

    // "on monday", "on friday", etc.
    final onDayRegex = RegExp(
      r'\bon\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      caseSensitive: false,
    );
    final onDayMatch = onDayRegex.firstMatch(text);
    if (onDayMatch != null) {
      final dayName = onDayMatch.group(1)!.toLowerCase();
      final targetDay = _dayOfWeek(dayName);
      var daysUntil = targetDay - now.weekday;
      if (daysUntil <= 0) daysUntil += 7;
      text = text.replaceFirst(onDayRegex, ' ');
      return (text, today.add(Duration(days: daysUntil)));
    }

    return (text, null);
  }

  static int _dayOfWeek(String day) {
    const days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return days[day] ?? 1;
  }

  static (String, DateTime?) _extractTime(String text) {
    // Normalize speech artifacts: "p.m." → "pm", "a.m." → "am"
    text = text.replaceAllMapped(
      RegExp(r'\b([ap])\.\s*m\.?', caseSensitive: false),
      (m) => '${m.group(1)!.toLowerCase()}m',
    );

    // Noon / midnight keywords
    final noonMidnightRegex = RegExp(
      r'\b(?:at\s+)?(noon|midnight)\b',
      caseSensitive: false,
    );
    final noonMidnightMatch = noonMidnightRegex.firstMatch(text);
    if (noonMidnightMatch != null) {
      final keyword = noonMidnightMatch.group(1)!.toLowerCase();
      final hour = keyword == 'noon' ? 12 : 0;
      final now = DateTime.now();
      text = text.replaceFirst(noonMidnightRegex, ' ');
      return (text, DateTime(now.year, now.month, now.day, hour, 0));
    }

    // Pattern 1: "at 5pm", "at 5:30pm", "at 5 pm", "at 5:30 pm"
    final atTimeRegex = RegExp(
      r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    final atTimeMatch = atTimeRegex.firstMatch(text);
    if (atTimeMatch != null) {
      final parsed = _parseAmPmTime(atTimeMatch.group(1)!, atTimeMatch.group(2), atTimeMatch.group(3)!);
      if (parsed != null) {
        text = text.replaceFirst(atTimeRegex, ' ');
        return (text, parsed);
      }
    }

    // Pattern 2: "at 14:30" (24-hour with "at")
    final at24Regex = RegExp(r'\bat\s+(\d{1,2}):(\d{2})\b', caseSensitive: false);
    final at24Match = at24Regex.firstMatch(text);
    if (at24Match != null) {
      final parsed = _parse24Time(at24Match.group(1)!, at24Match.group(2)!);
      if (parsed != null) {
        text = text.replaceFirst(at24Regex, ' ');
        return (text, parsed);
      }
    }

    // Pattern 3: standalone "5pm", "5:30pm", "5 pm", "5:30 pm" (without "at")
    final standaloneAmPmRegex = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    final standaloneMatch = standaloneAmPmRegex.firstMatch(text);
    if (standaloneMatch != null) {
      final parsed = _parseAmPmTime(standaloneMatch.group(1)!, standaloneMatch.group(2), standaloneMatch.group(3)!);
      if (parsed != null) {
        text = text.replaceFirst(standaloneAmPmRegex, ' ');
        return (text, parsed);
      }
    }

    // Pattern 4: standalone "14:30" (24-hour without "at")
    final standalone24Regex = RegExp(r'\b(\d{1,2}):(\d{2})\b');
    final standalone24Match = standalone24Regex.firstMatch(text);
    if (standalone24Match != null) {
      final hour = int.parse(standalone24Match.group(1)!);
      // Only treat as time if hour is in valid 24h range and > 0
      // (avoids matching things that look like ratios)
      if (hour >= 1 && hour <= 23) {
        final parsed = _parse24Time(standalone24Match.group(1)!, standalone24Match.group(2)!);
        if (parsed != null) {
          text = text.replaceFirst(standalone24Regex, ' ');
          return (text, parsed);
        }
      }
    }

    return (text, null);
  }

  static DateTime? _parseAmPmTime(String hourStr, String? minuteStr, String period) {
    var hour = int.parse(hourStr);
    final minute = minuteStr != null ? int.parse(minuteStr) : 0;
    final p = period.toLowerCase();
    if (hour < 1 || hour > 12 || minute > 59) return null;
    if (p == 'pm' && hour != 12) hour += 12;
    if (p == 'am' && hour == 12) hour = 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static DateTime? _parse24Time(String hourStr, String minuteStr) {
    final hour = int.parse(hourStr);
    final minute = int.parse(minuteStr);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static (String, String?) _extractCategory(String text, List<String> categoryNames) {
    if (categoryNames.isEmpty) return (text, null);

    // "for <category>" or "in <category>"
    for (final name in categoryNames) {
      final pattern = RegExp(
        '\\b(?:for|in)\\s+${RegExp.escape(name)}\\b',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match != null) {
        text = text.replaceFirst(pattern, ' ');
        return (text, name);
      }
    }
    return (text, null);
  }

  static String _cleanTitle(String text) {
    // Remove filler "and" at boundaries (e.g. "buy groceries and" → "buy groceries")
    text = text.replaceAll(RegExp(r'\band\s*$', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'^\s*and\b', caseSensitive: false), ' ');
    // Collapse multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Remove leading/trailing punctuation
    text = text.replaceAll(RegExp(r'^[\s,.\-:;!?]+|[\s,.\-:;!?]+$'), '').trim();
    // Capitalize first letter
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }
    return text;
  }
}
