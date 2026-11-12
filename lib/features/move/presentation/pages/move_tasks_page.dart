import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../domain/entities/move_task.dart';
import '../cubit/move_tasks_cubit.dart';

/// Relocation checklist: tick, add, rename (long-press) and delete (swipe).
class MoveTasksPage extends StatelessWidget {
  const MoveTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocConsumer<MoveTasksCubit, MoveTasksState>(
      listenWhen: (a, b) => b.errorMessage != null,
      listener: (context, state) =>
          showAppSnackBar(context, state.errorMessage!, isError: true),
      builder: (context, state) {
        return Scaffold(
          appBar: const ImukaAppBar(title: 'Move tasks'),
          body: SafeArea(
            top: false,
            bottom: false,
            child: state.status == RequestStatus.loading && state.tasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : PageBody(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${state.doneCount} of ${state.tasks.length} done',
                              style: context.text.titleSmall,
                            ),
                          ),
                          Text(
                            '${(state.progress * 100).round()}%',
                            style: context.text.labelMedium?.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressLine(value: state.progress),
                      for (final phase in TaskPhase.values) ...[
                        SectionTitle(
                          phase.label,
                          trailing: TextButton.icon(
                            onPressed: () => _addTask(context, phase),
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              textStyle: context.text.labelMedium,
                            ),
                          ),
                        ),
                        for (final task in state.tasksIn(phase))
                          _TaskRow(task: task),
                        if (state.tasksIn(phase).isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'No tasks yet.',
                              style: context.text.bodySmall,
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Tap to tick · long-press to rename · swipe to delete',
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: BottomActionBar(
            children: [
              PrimaryButton(
                label: 'Back to my move',
                onPressed: () => context.go(AppRoutes.move),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addTask(BuildContext context, TaskPhase phase) async {
    final cubit = context.read<MoveTasksCubit>();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _TaskTitleDialog(title: 'New task · ${phase.label}'),
    );
    if (title != null) cubit.add(title, phase);
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final MoveTask task;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cubit = context.read<MoveTasksCubit>();
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: p.danger,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) {
        cubit.delete(task.id);
        showAppSnackBar(
          context,
          'Task deleted',
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.add(task.title, task.phase),
          ),
        );
      },
      child: Semantics(
        checked: task.done,
        button: true,
        label: task.title,
        hint: 'Double tap to toggle. Long press to rename.',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () => cubit.toggle(task.id),
          onLongPress: () async {
            final title = await showDialog<String>(
              context: context,
              builder: (_) =>
                  _TaskTitleDialog(title: 'Rename task', initial: task.title),
            );
            if (title != null) cubit.rename(task.id, title);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Row(
              children: [
                CheckDot(checked: task.done, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (context.text.bodyMedium ?? const TextStyle())
                        .copyWith(
                          color: task.done ? p.textSecondary : p.textPrimary,
                          fontWeight: task.done
                              ? FontWeight.w500
                              : FontWeight.w600,
                        ),
                    child: Text(task.title),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text-entry dialog for adding or renaming a task.
class _TaskTitleDialog extends StatefulWidget {
  const _TaskTitleDialog({required this.title, this.initial = ''});

  final String title;
  final String initial;

  @override
  State<_TaskTitleDialog> createState() => _TaskTitleDialogState();
}

/// Stateful only to own the text controller and form key.
class _TaskTitleDialogState extends State<_TaskTitleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Pack the kitchen'),
          onFieldSubmitted: (_) => _save(),
          validator: (v) {
            final value = (v ?? '').trim();
            if (value.isEmpty) return 'Please enter a task.';
            if (value.length > 80) return 'Keep it under 80 characters.';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
