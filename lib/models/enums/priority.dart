/// Represents the urgency level of a task.
///
/// Each priority has an integer [value] (0 = high, 1 = medium, 2 = low)
/// and a human-readable [label].
enum Priority {
  high(0, 'High'),
  medium(1, 'Medium'),
  low(2, 'Low');

  const Priority(this.value, this.label);
  final int value;
  final String label;

  /// Returns the [Priority] matching [value], defaulting to [medium].
  static Priority fromValue(int value) {
    return Priority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => Priority.medium,
    );
  }
}
