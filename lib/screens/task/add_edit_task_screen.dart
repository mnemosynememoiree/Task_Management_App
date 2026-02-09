import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/feedback_utils.dart';
import '../../models/enums/priority.dart';
import '../../providers/task_provider.dart';
import '../../core/services/speech_service.dart';
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppStrings.title,
              hintText: AppStrings.titleHint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.mic_outlined),
                onPressed: () => _showVoiceToTextField(),
              ),
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

  void _showVoiceToTextField() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _VoiceToTextField(
        onTextConfirmed: (text) {
          _titleController.text = text;
        },
      ),
    );
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

class _VoiceToTextField extends StatefulWidget {
  final ValueChanged<String> onTextConfirmed;

  const _VoiceToTextField({required this.onTextConfirmed});

  @override
  State<_VoiceToTextField> createState() => _VoiceToTextFieldState();
}

class _VoiceToTextFieldState extends State<_VoiceToTextField> {
  final SpeechService _speech = SpeechService.instance;
  bool _isListening = false;
  String _recognizedText = '';
  String? _error;

  Future<void> _startListening() async {
    final available = await _speech.initialize();
    if (!available) {
      setState(() => _error = AppStrings.speechNotAvailable);
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _error = null;
    });

    await _speech.startListening(
      onResult: (result) {
        if (mounted) {
          setState(() => _recognizedText = result.recognizedWords);
        }
      },
    );
  }

  void _stopListening() {
    _speech.stopListening();
    setState(() => _isListening = false);
  }

  void _confirmText() {
    if (_recognizedText.trim().isNotEmpty) {
      widget.onTextConfirmed(_recognizedText.trim());
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    if (_isListening || _speech.isListening) _speech.cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom + mediaQuery.viewPadding.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.voiceInput,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _recognizedText.isEmpty
                  ? (_isListening ? AppStrings.speakNow : AppStrings.tapToSpeak)
                  : _recognizedText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _recognizedText.isEmpty
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                    fontStyle: _recognizedText.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'voice_field_mic',
                mini: true,
                onPressed: _isListening ? _stopListening : _startListening,
                backgroundColor:
                    _isListening ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                child: Icon(_isListening ? Icons.stop : Icons.mic),
              ),
              if (_recognizedText.isNotEmpty) ...[
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _confirmText,
                  child: const Text(AppStrings.useThisText),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
