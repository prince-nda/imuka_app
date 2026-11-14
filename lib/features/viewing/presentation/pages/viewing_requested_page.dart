import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../move/presentation/cubit/move_plan_cubit.dart';
import '../../../properties/presentation/cubit/property_search_cubit.dart';
import '../../domain/entities/viewing_request.dart';

/// Confirmation after a viewing request, leading into move planning.
class ViewingRequestedPage extends StatelessWidget {
  const ViewingRequestedPage({super.key, required this.request});

  final ViewingRequest request;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final to = context.select((PropertySearchCubit c) => c.state.filter.to);
    final ownerFirstName = request.ownerName.split(' ').first;
    final when =
        '${Formatters.longDate(request.scheduledAt)} · '
        '${DateFormat('HH:mm').format(request.scheduledAt)}';

    return Scaffold(
      appBar: const ImukaAppBar(title: 'Viewing requested'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: PageBody(
          children: [
            const SizedBox(height: 12),
            const Center(child: SuccessCheck()),
            const SizedBox(height: 20),
            Text(
              'Viewing requested!',
              textAlign: TextAlign.center,
              style: context.text.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$ownerFirstName usually replies in about '
              '${request.ownerReplyMinutes} minutes. We will confirm by SMS '
              'and ${request.channel.label}.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.muted,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  _DetailRow(icon: LucideIcons.calendar, text: when),
                  _DetailRow(
                    icon: LucideIcons.mapPin,
                    text: '${request.propertyTitle}, Kigali',
                  ),
                  _DetailRow(
                    icon: LucideIcons.shieldCheck,
                    iconColor: p.success,
                    text: 'Verified owner and listing',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: p.ink, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next: plan your move to ${to.label}',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'List what you are moving, get a cost estimate, book '
                    'movers and track them live.',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          PrimaryButton(
            label: 'Plan my move',
            onPressed: () {
              final filter = context.read<PropertySearchCubit>().state.filter;
              context.read<MovePlanCubit>().setRoute(filter.from, filter.to);
              context.go(AppRoutes.move);
            },
          ),
          const SizedBox(height: 4),
          LinkButton(
            label: 'Find another home',
            icon: LucideIcons.search,
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: context.text.titleSmall)),
        ],
      ),
    );
  }
}
