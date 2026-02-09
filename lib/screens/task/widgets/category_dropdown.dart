import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../providers/category_provider.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/skeleton_loader.dart';

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
          value: initialValue,
          decoration: const InputDecoration(
            labelText: AppStrings.category,
            prefixIcon: Icon(Icons.folder_outlined),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<int>(
              value: category.id,
              child: Row(
                children: [
                  Icon(
                    IconUtils.getIcon(category.icon),
                    size: 18,
                    color: Color(category.colorValue),
                  ),
                  const SizedBox(width: 8),
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
      loading: () => const ShimmerEffect(
        child: SizedBox(
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFE4E4E8),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
      error: (e, _) => ErrorState(
        message: AppStrings.somethingWentWrong,
        onRetry: () => ref.invalidate(categoriesStreamProvider),
      ),
    );
  }
}
