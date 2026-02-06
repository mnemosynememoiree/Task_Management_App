import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums/task_filter.dart';

final taskFilterProvider = StateProvider<TaskFilter>((ref) {
  return TaskFilter.today;
});
