import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/layout.dart';
import '../../domain/entities/move_item.dart';
import '../../domain/entities/mover.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/tracking_update.dart';

extension ItemCategoryIcon on ItemCategory {
  IconData get icon => switch (this) {
    ItemCategory.furniture => LucideIcons.house,
    ItemCategory.appliance => LucideIcons.zap,
    ItemCategory.boxes => LucideIcons.package,
    ItemCategory.other => LucideIcons.box,
  };
}

/// Item row with a − / + quantity stepper.
class MoveItemTile extends StatelessWidget {
  const MoveItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  final MoveItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppTheme.radiusMd,
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      child: Row(
        children: [
          IconTile(icon: item.category.icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                Text(item.category.label, style: context.text.bodySmall),
              ],
            ),
          ),
          _StepButton(
            icon: LucideIcons.minus,
            tooltip: 'Remove one ${item.name}',
            filled: false,
            onTap: item.quantity > 1 ? onDecrement : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: context.text.titleSmall,
              semanticsLabel: 'Quantity ${item.quantity}',
            ),
          ),
          _StepButton(
            icon: LucideIcons.plus,
            tooltip: 'Add one ${item.name}',
            filled: true,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        // 44×44 touch target around a 30pt visual circle.
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? p.ink : Colors.transparent,
                border: filled
                    ? null
                    : Border.all(color: enabled ? p.textSecondary : p.border),
              ),
              child: Icon(
                icon,
                size: 16,
                color: filled ? p.onInk : (enabled ? p.textPrimary : p.border),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable mover card with price, rating and "Best value" tag.
class MoverCard extends StatelessWidget {
  const MoverCard({
    super.key,
    required this.mover,
    required this.price,
    required this.itemCount,
    required this.selected,
    required this.isBestValue,
    required this.onTap,
  });

  final Mover mover;
  final int price;
  final int itemCount;
  final bool selected;
  final bool isBestValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${mover.name}, ${Formatters.rwf(price)}, rated ${mover.rating}'
          '${isBestValue ? ', best value' : ''}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? p.ink : p.border,
        borderWidth: selected ? 1.6 : 1,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(icon: LucideIcons.truck, dark: true, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mover.name, style: context.text.titleMedium),
                      const SizedBox(height: 4),
                      if (mover.verified)
                        const StatusBadge.verified(label: 'Verified mover'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.rwf(price),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('for $itemCount items', style: context.text.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star_rounded, color: p.star, size: 18),
                const SizedBox(width: 3),
                Text('${mover.rating}', style: context.text.labelMedium),
                Expanded(
                  child: Text(
                    '  ·  ${mover.summary}',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
            if (isBestValue) ...[
              const SizedBox(height: 10),
              const StatusBadge(label: 'Best value', tone: BadgeTone.highlight),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loaded → On the road → Arrived tracker.
class DeliveryStepper extends StatelessWidget {
  const DeliveryStepper({super.key, required this.stage});

  final TrackingStage stage;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stages = TrackingStage.values;
    return Semantics(
      label: 'Delivery status: ${stage.label}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                _Node(state: _nodeState(i)),
                if (i < stages.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 3,
                      color: i < stage.index ? p.success : p.border,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < stages.length; i++)
                Text(
                  stages[i].label,
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: i <= stage.index
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: i <= stage.index ? p.textPrimary : p.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _NodeState _nodeState(int i) {
    if (i < stage.index || stage == TrackingStage.arrived) {
      return _NodeState.done;
    }
    return i == stage.index ? _NodeState.current : _NodeState.upcoming;
  }
}

enum _NodeState { done, current, upcoming }

class _Node extends StatelessWidget {
  const _Node({required this.state});

  final _NodeState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == _NodeState.done ? p.success : p.card,
        border: Border.all(
          color: switch (state) {
            _NodeState.done => p.success,
            _NodeState.current => p.ink,
            _NodeState.upcoming => p.border,
          },
          width: state == _NodeState.current ? 2.5 : 2,
        ),
      ),
      child: switch (state) {
        _NodeState.done => Icon(
          LucideIcons.check,
          size: 15,
          color: p.onSuccess,
        ),
        _NodeState.current => Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
          ),
        ),
        _NodeState.upcoming => null,
      },
    );
  }
}

/// Radio-style payment method row.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '${method.label}, $subtitle',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        radius: AppTheme.radiusMd,
        borderColor: selected ? p.ink : p.border,
        borderWidth: selected ? 1.6 : 1,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconTile(
              icon: method.isMobileMoney
                  ? LucideIcons.phone
                  : LucideIcons.creditCard,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: context.text.titleSmall),
                  Text(subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? p.ink : p.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: p.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
