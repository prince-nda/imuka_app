import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/layout.dart';
import '../cubit/move_booking_cubit.dart';

/// Receipt and mover rating after payment.
class MoveCompletePage extends StatelessWidget {
  const MoveCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final booking = context.watch<MoveBookingCubit>().state;
    final receipt = booking.receipt;

    if (receipt == null) {
      return Scaffold(
        body: EmptyState(
          icon: LucideIcons.receipt,
          title: 'No completed move yet',
          message: 'Your receipt appears here after you pay your movers.',
          actionLabel: 'Back to my move',
          onAction: () => context.go(AppRoutes.move),
        ),
      );
    }

    final rows = [
      ('Date', Formatters.longDate(receipt.plan.date)),
      ('Route', receipt.plan.routeLabel),
      ('Paid with', receipt.method.label),
      ('Receipt', receipt.reference),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageBody(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            32,
            AppTheme.pagePadding,
            24,
          ),
          children: [
            const Center(child: SuccessCheck()),
            const SizedBox(height: 20),
            Text(
              'Move complete!',
              textAlign: TextAlign.center,
              style: context.text.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'All items were delivered.\n'
              '${Formatters.rwf(receipt.amount)} paid to ${receipt.moverName}.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: p.muted,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  for (final (label, value) in rows)
                    KeyValueRow(
                      label: label,
                      value: value,
                      showDivider: false,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rate ${receipt.moverName}',
              textAlign: TextAlign.center,
              style: context.text.titleSmall,
            ),
            const SizedBox(height: 4),
            _StarRating(
              value: booking.rating,
              onChanged: (stars) {
                context.read<MoveBookingCubit>().rate(stars);
                showAppSnackBar(context, 'Thanks! Your rating helps others.');
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          PrimaryButton(
            label: 'View my move tasks',
            onPressed: () => context.go(AppRoutes.moveTasks),
          ),
          const SizedBox(height: 4),
          LinkButton(
            label: 'Back to home',
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            tooltip: '$star star${star == 1 ? '' : 's'}',
            onPressed: () => onChanged(star),
            icon: AnimatedScale(
              scale: star <= value ? 1.1 : 1,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: p.star,
                size: 34,
              ),
            ),
          ),
      ],
    );
  }
}
