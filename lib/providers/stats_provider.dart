import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

final totalTaskCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.countTotal();
});

final completedTodayCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.countCompletedToday();
});

final overdueCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.countOverdue();
});

final weeklyCompletionRateProvider = StreamProvider<double>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.weeklyCompletionRate();
});
