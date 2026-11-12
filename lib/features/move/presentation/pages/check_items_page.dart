import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../domain/entities/move_item.dart';
import '../cubit/delivery_check_cubit.dart';
import '../cubit/move_plan_cubit.dart';
import '../cubit/move_tasks_cubit.dart';

/// Moving-day check: tick every item before the payment unlocks.
class CheckItemsPage extends StatelessWidget {
  const CheckItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DeliveryCheckCubit(context.read<MovePlanCubit>().state.items),
      child: const _CheckItemsView(),
    );
  }
}

class _CheckItemsView extends StatelessWidget {
  const _CheckItemsView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.watch<DeliveryCheckCubit>().state;
    final cubit = context.read<DeliveryCheckCubit>();
    final total = state.items.length;
    // The first unticked item is highlighted as "Tap to tick".
    final nextId = state.items
        .where(
          (i) => !state.isReceived(i.id) && !state.issues.containsKey(i.id),
        )
        .map((i) => i.id)
        .firstOrNull;

    return Scaffold(
      appBar: const ImukaAppBar(title: 'Check your items'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: PageBody(
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      state.canPay
                          ? 'All $total items received'
                          : '${state.receivedCount} of $total items received',
                      style: context.text.titleSmall,
                    ),
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
            const SizedBox(height: 12),
            Text(
              state.canPay
                  ? 'Everything has arrived. You can now pay your movers.'
                  : 'Tick each item as it arrives at your new home. You can '
                        'pay once all $total are ticked.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 14),
            for (final item in state.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CheckTile(
                  item: item,
                  received: state.isReceived(item.id),
                  issue: state.issues[item.id],
                  isNext: item.id == nextId,
                  onTap: () => state.issues.containsKey(item.id)
                      ? _resolveIssue(context, item)
                      : cubit.toggle(item.id),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          TextButton(
            onPressed: () => _reportIssue(context),
            style: TextButton.styleFrom(foregroundColor: p.danger),
            child: Text(
              'Something missing or damaged? Report it',
              style: context.text.labelMedium?.copyWith(color: p.danger),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: state.canPay
                ? 'Continue to payment'
                : state.issues.isNotEmpty
                ? 'Resolve issues to pay'
                : 'Confirm all items to pay',
            trailingIcon: state.canPay ? LucideIcons.arrowRight : null,
            onPressed: state.canPay
                ? () {
                    context.read<MoveTasksCubit>().completeMatching(
                      'Check every item',
                    );
                    context.push(AppRoutes.payment);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _reportIssue(BuildContext context) async {
    final cubit = context.read<DeliveryCheckCubit>();
    final item = await showModalBottomSheet<MoveItem>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Which item has a problem?',
                  style: sheetContext.text.titleLarge,
                ),
              ),
              for (final item in cubit.state.items)
                ListTile(
                  minTileHeight: 56,
                  title: Text(item.name),
                  subtitle: Text('${item.category.label} ×${item.quantity}'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Navigator.of(sheetContext).pop(item),
                ),
            ],
          ),
        ),
      ),
    );
    if (item == null || !context.mounted) return;
    final description = await showDialog<String>(
      context: context,
      builder: (_) => _IssueDialog(item: item),
    );
    if (description == null || !context.mounted) return;
    cubit.reportIssue(item.id, description);
    showAppSnackBar(
      context,
      'Issue reported. Payment stays on hold until it\'s resolved.',
      isError: true,
    );
  }

  Future<void> _resolveIssue(BuildContext context, MoveItem item) async {
    final cubit = context.read<DeliveryCheckCubit>();
    final resolved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Is ${item.name} OK now?'),
        content: const Text(
          'Mark the issue as resolved if the movers found or fixed it. '
          'You can then tick the item.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Resolved'),
          ),
        ],
      ),
    );
    if (resolved ?? false) cubit.resolveIssue(item.id);
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.item,
    required this.received,
    required this.issue,
    required this.isNext,
    required this.onTap,
  });

  final MoveItem item;
  final bool received;
  final String? issue;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasIssue = issue != null;
    return Semantics(
      checked: received,
      button: true,
      label:
          '${item.name}, ${item.category.label} times ${item.quantity}'
          '${hasIssue ? ', issue reported: $issue' : ''}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        radius: AppTheme.radiusMd,
        color: received ? p.muted : p.card,
        borderColor: hasIssue
            ? p.danger
            : isNext
            ? p.ink
            : p.border,
        borderWidth: hasIssue || isNext ? 1.5 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            hasIssue
                ? Icon(LucideIcons.triangleAlert, color: p.danger, size: 26)
                : CheckDot(checked: received),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: context.text.titleSmall?.copyWith(
                      color: received ? p.textSecondary : p.textPrimary,
                    ),
                  ),
                  Text(
                    hasIssue
                        ? 'Issue: $issue'
                        : '${item.category.label} ×${item.quantity}',
                    style: context.text.bodySmall?.copyWith(
                      color: hasIssue ? p.danger : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isNext)
              Text('Tap to tick', style: context.text.labelMedium)
            else if (hasIssue)
              Text(
                'Tap to resolve',
                style: context.text.labelMedium?.copyWith(color: p.danger),
              ),
          ],
        ),
      ),
    );
  }
}

/// Asks what went wrong; resolves with the description.
class _IssueDialog extends StatefulWidget {
  const _IssueDialog({required this.item});

  final MoveItem item;

  @override
  State<_IssueDialog> createState() => _IssueDialogState();
}

/// Stateful only to own the text controller and form key.
class _IssueDialogState extends State<_IssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.item.name}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Missing, or the glass door is cracked',
          ),
          validator: (v) => (v ?? '').trim().length < 3
              ? 'Please describe the problem in a few words.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Report')),
      ],
    );
  }
}
