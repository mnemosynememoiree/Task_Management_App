/// Filter options for displaying tasks based on their due date status.
enum TaskFilter {
  today('Today'),
  upcoming('Upcoming'),
  overdue('Overdue'),
  all('All');

  const TaskFilter(this.label);
  final String label;
}
