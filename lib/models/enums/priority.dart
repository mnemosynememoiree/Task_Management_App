enum Priority {
  high(0, 'High'),
  medium(1, 'Medium'),
  low(2, 'Low');

  const Priority(this.value, this.label);
  final int value;
  final String label;

  static Priority fromValue(int value) {
    return Priority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => Priority.medium,
    );
  }
}
