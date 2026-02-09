import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback_utils.dart';
import '../../models/enums/priority.dart';
import '../../providers/task_provider.dart';
import '../../widgets/confirm_dialog.dart';
import 'widgets/priority_selector.dart';
import 'widgets/date_time_picker.dart';
import 'widgets/category_dropdown.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final int? taskId;
  final int? initialCategoryId;

  const AddEditTaskScreen({
    super.key,
    this.taskId,
    this.initialCategoryId,
  });

  bool get isEditing => taskId != null;

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  DateTime? _dueTime;
  int _categoryId = 1;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadTask();
    } else {
      _isLoading = false;
      if (widget.initialCategoryId != null) {
        _categoryId = widget.initialCategoryId!;
      }
    }
  }

  Future<void> _loadTask() async {
    try {
      final task = await ref.read(taskByIdProvider(widget.taskId!).future);
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _priority = Priority.fromValue(task.priority);
      _dueDate = task.dueDate;
      _dueTime = task.dueTime;
      _categoryId = task.categoryId;
    } catch (e) {
      if (mounted) context.pop();
      return;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? AppStrings.editTask : AppStrings.addTask),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: AppStrings.title,
              hintText: AppStrings.titleHint,
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: !widget.isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.titleRequired;
              }
              if (value.length > 200) {
                return AppStrings.titleMaxLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: '${AppStrings.description} (${AppStrings.optional})',
              hintText: AppStrings.descriptionHint,
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.priority,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          PrioritySelector(
            selected: _priority,
            onChanged: (p) => setState(() => _priority = p),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.dueDate,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DateTimePicker(
            selectedDate: _dueDate,
            selectedTime: _dueTime,
            onDateChanged: (d) => setState(() => _dueDate = d),
            onTimeChanged: (t) => setState(() => _dueTime = t),
          ),
          const SizedBox(height: 24),
          CategoryDropdown(
            selectedCategoryId: _categoryId,
            onChanged: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSaving ? null : _saveTask,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppStrings.save,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final notifier = ref.read(taskNotifierProvider.notifier);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      if (widget.isEditing) {
        await notifier.updateTask(
          id: widget.taskId!,
          title: title,
          description: description.isEmpty ? null : description,
          priority: _priority.value,
          dueDate: _dueDate,
          dueTime: _dueTime,
          categoryId: _categoryId,
        );
      } else {
        await notifier.addTask(
          title: title,
          description: description.isEmpty ? null : description,
          priority: _priority.value,
          dueDate: _dueDate,
          dueTime: _dueTime,
          categoryId: _categoryId,
        );
      }

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          widget.isEditing ? AppStrings.taskUpdated : AppStrings.taskCreated,
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showError(context, AppStrings.somethingWentWrong);
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteTask,
      message: AppStrings.deleteTaskConfirm,
    );
    if (confirmed == true) {
      final companion = await ref
          .read(taskNotifierProvider.notifier)
          .deleteTaskWithUndo(widget.taskId!);
      if (mounted) {
        context.pop();
        if (companion != null) {
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
}
