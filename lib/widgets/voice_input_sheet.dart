import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/utils/feedback_utils.dart';
import '../models/enums/priority.dart';
import '../providers/category_provider.dart';
import '../providers/speech_provider.dart';
import '../providers/task_provider.dart';

class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const VoiceInputSheet(),
    );
  }

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Editable fields for "done" state
  final _titleController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  List<String> _getCategoryNames() {
    final categories = ref.read(categoriesStreamProvider).valueOrNull ?? [];
    return categories.map((c) => c.name).toList();
  }

  int? _getCategoryIdByName(String? name) {
    if (name == null) return null;
    final categories = ref.read(categoriesStreamProvider).valueOrNull ?? [];
    for (final c in categories) {
      if (c.name.toLowerCase() == name.toLowerCase()) return c.id;
    }
    return null;
  }

  void _onParseComplete(SpeechState state) {
    final parsed = state.parsedTask;
    if (parsed != null) {
      _titleController.text = parsed.title;
      _selectedPriority = parsed.priority;
      _selectedDate = parsed.dueDate;
      _selectedTime = parsed.dueTime;
      _selectedCategoryName = parsed.categoryName;
    }
  }

  Future<void> _createTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      final categoryId = _getCategoryIdByName(_selectedCategoryName) ?? 1;

      await ref.read(taskNotifierProvider.notifier).addTask(
            title: title,
            priority: _selectedPriority.value,
            dueDate: _selectedDate,
            dueTime: _selectedTime,
            categoryId: categoryId,
          );

      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(context, AppStrings.voiceTaskCreated);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, AppStrings.somethingWentWrong);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final initial = _selectedTime != null
        ? TimeOfDay(hour: _selectedTime!.hour, minute: _selectedTime!.minute)
        : TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechNotifierProvider);

    // Sync editable fields when transitioning to done
    ref.listen<SpeechState>(speechNotifierProvider, (prev, next) {
      if (prev?.status != SpeechStatus.done && next.status == SpeechStatus.done) {
        _onParseComplete(next);
      }
    });

    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom + mediaQuery.viewPadding.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.voiceInput,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (speechState.status == SpeechStatus.listening ||
                      speechState.status == SpeechStatus.processing)
                    TextButton(
                      onPressed: () {
                        ref.read(speechNotifierProvider.notifier).cancel();
                      },
                      child: const Text(AppStrings.cancel),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // State-driven content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildContent(speechState),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SpeechState speechState) {
    switch (speechState.status) {
      case SpeechStatus.idle:
      case SpeechStatus.initializing:
        return _buildIdleState(speechState);
      case SpeechStatus.listening:
        return _buildListeningState(speechState);
      case SpeechStatus.processing:
        return _buildProcessingState();
      case SpeechStatus.done:
        return _buildDoneState(speechState);
      case SpeechStatus.error:
        return _buildErrorState(speechState);
    }
  }

  Widget _buildIdleState(SpeechState speechState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          AppStrings.tapToSpeak,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        FloatingActionButton.large(
          heroTag: 'voice_idle_mic',
          onPressed: speechState.status == SpeechStatus.initializing
              ? null
              : () => ref.read(speechNotifierProvider.notifier).startListening(),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: speechState.status == SpeechStatus.initializing
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Icon(Icons.mic, size: 36),
        ),
        const SizedBox(height: 24),
        // Voice guide
        _buildVoiceGuide(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVoiceGuide() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            AppStrings.voiceGuideTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildGuideCard(
          icon: Icons.calendar_today,
          color: AppColors.primary,
          label: AppStrings.voiceGuideDate,
          examples: const ['tomorrow', 'today', 'in 3 days', 'feb 12', 'march 3rd 2027', 'next monday'],
        ),
        const SizedBox(height: 8),
        _buildGuideCard(
          icon: Icons.access_time,
          color: AppColors.success,
          label: AppStrings.voiceGuideTime,
          examples: const ['5pm', 'at 10:30 am', 'noon', 'midnight'],
        ),
        const SizedBox(height: 8),
        _buildGuideCard(
          icon: Icons.flag_outlined,
          color: AppColors.priorityHigh,
          label: AppStrings.voiceGuidePriority,
          examples: const ['high priority', 'priority low', 'urgent', 'no rush'],
        ),
        const SizedBox(height: 8),
        _buildGuideCard(
          icon: Icons.folder_outlined,
          color: const Color(0xFF8B5CF6),
          label: AppStrings.voiceGuideCategory,
          examples: const ['for Work', 'in Shopping'],
        ),
        const SizedBox(height: 12),
        // Full example
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.format_quote, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.voiceGuideFullExample,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required Color color,
    required String label,
    required List<String> examples,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: examples.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningState(SpeechState speechState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          AppStrings.listening,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        // Live partial text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            speechState.recognizedText.isEmpty
                ? AppStrings.speakNow
                : speechState.recognizedText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: speechState.recognizedText.isEmpty
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                  fontStyle: speechState.recognizedText.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
          ),
        ),
        const SizedBox(height: 24),
        // Pulsing stop button
        ScaleTransition(
          scale: _pulseAnimation,
          child: FloatingActionButton(
            heroTag: 'voice_stop_mic',
            onPressed: () {
              ref.read(speechNotifierProvider.notifier).finishAndParse(
                    categoryNames: _getCategoryNames(),
                  );
            },
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            child: const Icon(Icons.stop, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.tapToStop,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProcessingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 48),
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(AppStrings.processing),
        SizedBox(height: 48),
      ],
    );
  }

  Widget _buildDoneState(SpeechState speechState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.editBeforeCreating,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        // Title
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: AppStrings.title,
            hintText: AppStrings.titleHint,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        // Date & Time chips
        Row(
          children: [
            Expanded(
              child: ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _selectedDate != null
                      ? DateFormat.yMMMd().format(_selectedDate!)
                      : AppStrings.addDueDate,
                ),
                onPressed: _pickDate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionChip(
                avatar: const Icon(Icons.access_time, size: 16),
                label: Text(
                  _selectedTime != null
                      ? DateFormat.jm().format(_selectedTime!)
                      : AppStrings.addTime,
                ),
                onPressed: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Priority
        Text(
          AppStrings.priority,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: Priority.values.map((p) {
            final isSelected = _selectedPriority == p;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(p.label),
                  selected: isSelected,
                  selectedColor: AppColors.colorForPriority(p).withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _selectedPriority = p),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Category indicator
        if (_selectedCategoryName != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(Icons.folder_outlined, size: 16),
              label: Text(_selectedCategoryName!),
              onDeleted: () => setState(() => _selectedCategoryName = null),
            ),
          ),
        const SizedBox(height: 24),
        // Action buttons
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _createTask,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              AppStrings.createTaskButton,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            ref.read(speechNotifierProvider.notifier).reset();
          },
          child: const Text(AppStrings.tryAgain),
        ),
      ],
    );
  }

  Widget _buildErrorState(SpeechState speechState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 12),
        Text(
          speechState.errorMessage ?? AppStrings.somethingWentWrong,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        FloatingActionButton(
          heroTag: 'voice_retry_mic',
          onPressed: () {
            ref.read(speechNotifierProvider.notifier).reset();
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.mic),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.tryAgain,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
