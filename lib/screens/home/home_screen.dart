import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/daos/task_dao.dart';
import '../../models/enums/task_sort.dart';
import '../../providers/search_provider.dart';
import '../../providers/sort_provider.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_tile.dart';
import '../../providers/task_provider.dart';
import '../../core/utils/feedback_utils.dart';
import '../../widgets/confirm_dialog.dart';
import 'widgets/date_tab_bar.dart';
import 'widgets/stats_summary.dart';
import 'widgets/task_list_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  bool _showStats = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      }
    });
  }

  void _showSortOptions() {
    final currentSort = ref.read(taskSortProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  AppStrings.sortBy,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              ...TaskSort.values.map((sort) {
                return ListTile(
                  title: Text(sort.label),
                  trailing: currentSort == sort
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(taskSortProvider.notifier).state = sort;
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchTasks,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              )
            : const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptions,
            ),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (_showStats) ...[
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                setState(() => _showStats = false);
              }
            },
            child: const StatsSummary(),
          ),
          const SizedBox(height: 4),
        ],
        const DateTabBar(),
        const SizedBox(height: 8),
        const Expanded(child: TaskListSection()),
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: AppStrings.search,
        subtitle: AppStrings.searchTasks,
      );
    }

    return searchAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: AppStrings.noSearchResults,
            subtitle: AppStrings.noSearchResultsSubtitle,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tc = tasks[index];
            return AnimatedListItem(
              index: index,
              child: TaskTile(
                taskWithCategory: tc,
                index: index,
                onToggle: (value) {
                  ref
                      .read(taskNotifierProvider.notifier)
                      .toggleCompletion(tc.task.id, value ?? false);
                  if (value == true) {
                    AppFeedback.showSuccess(context, AppStrings.taskCompleted);
                  }
                },
                onTap: () => context.push('/tasks/edit/${tc.task.id}'),
                onDelete: () => _deleteTaskWithUndo(tc),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Future<void> _deleteTaskWithUndo(TaskWithCategory tc) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteTask,
      message: AppStrings.deleteTaskConfirm,
    );
    if (confirmed == true && mounted) {
      final companion = await ref
          .read(taskNotifierProvider.notifier)
          .deleteTaskWithUndo(tc.task.id);
      if (companion != null && mounted) {
        AppFeedback.showUndoable(
          context,
          AppStrings.taskDeleted,
          onUndo: () {
            ref.read(taskNotifierProvider.notifier).restoreTask(companion);
          },
        );
      }
    }
  }
}
