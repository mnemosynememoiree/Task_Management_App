import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums/task_sort.dart';

final taskSortProvider = StateProvider<TaskSort>((ref) {
  return TaskSort.priorityAsc;
});
