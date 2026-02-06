enum TaskFilter {
  today('Today'),
  upcoming('Upcoming'),
  overdue('Overdue'),
  all('All');

  const TaskFilter(this.label);
  final String label;
}
