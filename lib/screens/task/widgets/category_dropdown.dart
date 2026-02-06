import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/category_provider.dart';

class CategoryDropdown extends ConsumerWidget {
  final int selectedCategoryId;
  final ValueChanged<int> onChanged;

  const CategoryDropdown({
    super.key,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      data: (categories) {
        final initialValue = categories.any((c) => c.id == selectedCategoryId)
            ? selectedCategoryId
            : categories.first.id;
        return DropdownButtonFormField<int>(
          initialValue: initialValue,
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.folder_outlined),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<int>(
              value: category.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(category.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error loading categories: $e'),
    );
  }
}
