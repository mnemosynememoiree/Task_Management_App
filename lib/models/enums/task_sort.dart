enum TaskSort {
  priorityAsc('Priority'),
  dueDateAsc('Due date (earliest)'),
  dueDateDesc('Due date (latest)'),
  titleAsc('Title (A-Z)'),
  createdAtDesc('Newest first');

  const TaskSort(this.label);
  final String label;
}
