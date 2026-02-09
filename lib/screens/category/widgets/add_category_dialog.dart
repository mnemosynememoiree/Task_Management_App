import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/feedback_utils.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/category_provider.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final Category? category;

  const AddCategoryDialog({super.key, this.category});

  bool get isEditing => category != null;

  static Future<void> show(BuildContext context, {Category? category}) {
    return showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(category: category),
    );
  }

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;
  bool _isSaving = false;

  static const _presetIcons = [
    'category',
    'work',
    'person',
    'home',
    'school',
    'fitness_center',
    'shopping_cart',
    'favorite',
    'star',
    'code',
    'music_note',
    'restaurant',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? 'category';
    _selectedColor = widget.category?.colorValue ?? AppColors.categoryColors.first.toARGB32();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEditing ? AppStrings.editCategory : AppStrings.addCategory,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.categoryName,
                  hintText: AppStrings.categoryHint,
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.categoryNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.iconLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetIcons.map((iconName) {
                  final isSelected = iconName == _selectedIcon;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIcon = iconName);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withValues(alpha: 0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColor)
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        IconUtils.getIcon(iconName),
                        size: 20,
                        color: isSelected
                            ? Color(_selectedColor)
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.colorLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.categoryColors.map((color) {
                  final isSelected = color.toARGB32() == _selectedColor;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColor = color.toARGB32());
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: AppColors.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(categoryNotifierProvider.notifier);
    final name = _nameController.text.trim();

    // Check for duplicate name
    final exists = await notifier.categoryNameExists(
      name,
      excludeId: widget.category?.id,
    );
    if (exists) {
      if (mounted) {
        _formKey.currentState!.validate();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
                content: Text(AppStrings.categoryNameDuplicate)),
          );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing) {
        await notifier.updateCategory(
          id: widget.category!.id,
          name: name,
          icon: _selectedIcon,
          colorValue: _selectedColor,
        );
      } else {
        await notifier.addCategory(
          name: name,
          icon: _selectedIcon,
          colorValue: _selectedColor,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(
          context,
          widget.isEditing
              ? AppStrings.categoryUpdated
              : AppStrings.categoryCreated,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showError(context, AppStrings.somethingWentWrong);
      }
    }
  }
}
