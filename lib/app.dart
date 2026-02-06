import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/category/category_list_screen.dart';
import 'screens/category/category_detail_screen.dart';
import 'screens/task/add_edit_task_screen.dart';
import 'widgets/app_bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/tasks',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppBottomNav(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoryListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return CategoryDetailScreen(categoryId: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/tasks/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final categoryId = state.uri.queryParameters['categoryId'];
        return AddEditTaskScreen(
          initialCategoryId:
              categoryId != null ? int.tryParse(categoryId) : null,
        );
      },
    ),
    GoRoute(
      path: '/tasks/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddEditTaskScreen(taskId: id);
      },
    ),
  ],
);

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tasks',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
