import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../providers/stats_provider.dart';

class StatsSummary extends ConsumerWidget {
  const StatsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalTaskCountProvider);
    final completedTodayAsync = ref.watch(completedTodayCountProvider);
    final overdueAsync = ref.watch(overdueCountProvider);
    final weeklyRateAsync = ref.watch(weeklyCompletionRateProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _StatCard(
            label: 'Total',
            value: totalAsync.valueOrNull?.toString() ?? '-',
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Done today',
            value: completedTodayAsync.valueOrNull?.toString() ?? '-',
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Overdue',
            value: overdueAsync.valueOrNull?.toString() ?? '-',
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: 'Weekly',
            value: weeklyRateAsync.valueOrNull != null
                ? '${(weeklyRateAsync.valueOrNull! * 100).round()}%'
                : '-',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
