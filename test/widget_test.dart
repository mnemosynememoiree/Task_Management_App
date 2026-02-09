import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do_app/models/enums/priority.dart';
import 'package:to_do_app/widgets/empty_state.dart';
import 'package:to_do_app/widgets/priority_indicator.dart';

void main() {
  group('EmptyState widget', () {
    testWidgets('renders title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No tasks',
              subtitle: 'Add a task to get started',
            ),
          ),
        ),
      );

      expect(find.text('No tasks'), findsOneWidget);
      expect(find.text('Add a task to get started'), findsOneWidget);
    });

    testWidgets('renders action button when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              subtitle: 'Nothing here',
              actionLabel: 'Add Task',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('hides action button when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              subtitle: 'Nothing here',
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('PriorityIndicator widget', () {
    testWidgets('renders as a colored circle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriorityIndicator(priority: Priority.high),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });
  });
}
