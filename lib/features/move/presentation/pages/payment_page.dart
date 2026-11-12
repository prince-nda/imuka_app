import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/payment.dart';
import '../cubit/move_booking_cubit.dart';
import '../cubit/move_plan_cubit.dart';
import '../widgets/move_widgets.dart';

/// Pay the locked-in price after confirming delivery.
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final planState = context.watch<MovePlanCubit>().state;
    final booking = context.watch<MoveBookingCubit>().state;
    final phone = context.select((AuthCubit c) => c.state.user?.phone ?? '');
    final mover = booking.bookedMover;

    if (mover == null) {
      return Scaffold(
        appBar: const ImukaAppBar(title: 'Pay for your move'),
        body: EmptyState(
          icon: LucideIcons.truck,
          title: 'No mover booked',
          message: 'Book a mover before paying.',
          actionLabel: 'Choose movers',
          onAction: () => context.pushReplacement(AppRoutes.movers),
        ),
      );
    }

    final estimate = planState.estimate;
    final total = estimate.quoteFor(mover);
    final rows = [
      ('Items (${estimate.itemCount})', estimate.itemsTotal),
      ('Truck and fuel', estimate.transportFee),
      ('Loaders (${estimate.loaders})', estimate.loadersFee),
      if (mover.priceAdjustment != 0)
        (
          mover.priceAdjustment < 0 ? '${mover.name} discount' : 'Mover fee',
          mover.priceAdjustment,
        ),
    ];
    String subtitleFor(PaymentMethod m) => switch (m) {
      PaymentMethod.card => m.description,
      _ => phone.isEmpty ? m.description : Formatters.phone(phone),
    };

    return BlocListener<MoveBookingCubit, MoveBookingState>(
      listenWhen: (a, b) => a.paymentStatus != b.paymentStatus,
      listener: (context, state) {
        if (state.paymentStatus == RequestStatus.failure) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
        if (state.paymentStatus == RequestStatus.success) {
          context.go(AppRoutes.moveComplete);
        }
      },
      child: Scaffold(
        appBar: const ImukaAppBar(title: 'Pay for your move'),
        body: SafeArea(
          top: false,
          bottom: false,
          child: PageBody(
            children: [
              AppCard(
                color: p.muted,
                borderColor: Colors.transparent,
                radius: AppTheme.radiusMd,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.success,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.check, color: p.onSuccess),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All ${estimate.itemCount} items received',
                            style: context.text.titleSmall,
                          ),
                          Text(
                            'Confirmed at your new home in '
                            '${planState.plan.to.label}',
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(mover.name, style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    for (final (label, amount) in rows)
                      KeyValueRow(
                        label: label,
                        value: amount < 0
                            ? '− ${Formatters.rwf(-amount)}'
                            : Formatters.rwf(amount),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        showDivider: label == rows.last.$1,
                      ),
                    KeyValueRow(
                      label: 'Total',
                      value: Formatters.rwf(total),
                      emphasize: true,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SectionTitle('Pay with'),
              for (final method in PaymentMethod.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PaymentMethodTile(
                    method: method,
                    subtitle: subtitleFor(method),
                    selected: booking.paymentMethod == method,
                    onTap: () => context
                        .read<MoveBookingCubit>()
                        .selectPaymentMethod(method),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          children: [
            PrimaryButton(
              label: 'Pay ${Formatters.rwf(total)}',
              isLoading: booking.paymentStatus.isLoading,
              onPressed: () => context.read<MoveBookingCubit>().pay(
                plan: planState.plan,
                amount: total,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.lock, size: 13, color: p.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Released to ${mover.name} after your confirmation',
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
