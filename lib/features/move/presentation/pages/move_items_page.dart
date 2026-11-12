import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/pickers.dart';
import '../../domain/entities/move_item.dart';
import '../cubit/move_plan_cubit.dart';
import '../widgets/move_widgets.dart';

/// "What are you moving?" — create, update and delete move items.
class MoveItemsPage extends StatefulWidget {
  const MoveItemsPage({super.key});

  @override
  State<MoveItemsPage> createState() => _MoveItemsPageState();
}

/// Stateful only to own the "add item" controller.
class _MoveItemsPageState extends State<MoveItemsPage> {
  final _formKey = GlobalKey<FormState>();
  final _newItem = TextEditingController();

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  void _add() {
    if (!_formKey.currentState!.validate()) return;
    context.read<MovePlanCubit>().addItem(_newItem.text);
    _newItem.clear();
    _formKey.currentState!.reset();
  }

  void _remove(MoveItem item) {
    final cubit = context.read<MovePlanCubit>();
    cubit.removeItem(item.id);
    showAppSnackBar(
      context,
      '${item.name} removed',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => cubit.restoreItem(item),
      ),
    );
  }

  Future<void> _clearAll() async {
    final cubit = context.read<MovePlanCubit>();
    final confirmed = await confirmDialog(
      context: context,
      title: 'Clear all items?',
      message:
          'This removes every item from your list. You can add them '
          'again later.',
      confirmLabel: 'Clear all',
    );
    if (confirmed) cubit.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocConsumer<MovePlanCubit, MovePlanState>(
      listenWhen: (a, b) => b.errorMessage != null,
      listener: (context, state) =>
          showAppSnackBar(context, state.errorMessage!, isError: true),
      builder: (context, state) {
        final estimate = state.estimate;
        final items = state.items;
        return Scaffold(
          appBar: const ImukaAppBar(title: 'What are you moving?'),
          body: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                4,
                AppTheme.pagePadding,
                24,
              ),
              children: [
                ResponsiveCenter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _newItem,
                                hint: 'Add an item, e.g. Bicycle',
                                prefixIcon: LucideIcons.list,
                                textInputAction: TextInputAction.done,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                validator: Validators.itemName,
                                onSubmitted: (_) => _add(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox.square(
                              dimension: 56,
                              child: IconButton.filled(
                                tooltip: 'Add item',
                                onPressed: _add,
                                style: IconButton.styleFrom(
                                  backgroundColor: p.ink,
                                  foregroundColor: p.onInk,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                ),
                                icon: const Icon(LucideIcons.plus),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SectionTitle(
                        'Your items (${items.length})',
                        trailing: items.isEmpty
                            ? null
                            : TextButton(
                                onPressed: _clearAll,
                                child: Text(
                                  'Clear all',
                                  style: context.text.labelMedium?.copyWith(
                                    color: p.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                      if (state.status == RequestStatus.loading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (items.isEmpty)
                        const EmptyState(
                          icon: LucideIcons.package,
                          title: 'Nothing listed yet',
                          message:
                              'Add furniture, appliances and boxes to '
                              'get an upfront price.',
                        )
                      else
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _remove(item),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: p.danger,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.trash2,
                                  color: Colors.white,
                                ),
                              ),
                              child: MoveItemTile(
                                item: item,
                                onIncrement: () => context
                                    .read<MovePlanCubit>()
                                    .increment(item.id),
                                onDecrement: () => context
                                    .read<MovePlanCubit>()
                                    .decrement(item.id),
                              ),
                            ),
                          ),
                      if (items.isNotEmpty)
                        Text(
                          'Swipe left on an item to remove it.',
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomActionBar(
            showDivider: true,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated cost', style: context.text.bodySmall),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            Formatters.rwf(estimate.total),
                            key: ValueKey(estimate.total),
                            style: context.text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${estimate.itemCount} items',
                        style: context.text.titleSmall,
                      ),
                      Text(
                        '${state.plan.routeLabel} · ${state.plan.distanceKm} km',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'See cost estimate',
                onPressed: items.isEmpty
                    ? null
                    : () => context.push(AppRoutes.moveCosts),
              ),
            ],
          ),
        );
      },
    );
  }
}
