import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/daos/task_dao.dart';
import 'database_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = StreamProvider<List<TaskWithCategory>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Stream.value([]);
  final dao = ref.watch(taskDaoProvider);
  return dao.watchSearchResults(query.trim());
});
