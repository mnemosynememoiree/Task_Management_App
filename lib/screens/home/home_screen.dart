import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import 'widgets/date_tab_bar.dart';
import 'widgets/task_list_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
      ),
      body: const Column(
        children: [
          DateTabBar(),
          SizedBox(height: 8),
          Expanded(child: TaskListSection()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
