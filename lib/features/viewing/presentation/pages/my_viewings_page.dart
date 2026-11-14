import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/pickers.dart';
import '../../domain/entities/viewing_request.dart';
import '../../domain/repositories/viewing_repository.dart';
import '../cubit/my_viewings_cubit.dart';

/// Viewing requests the user has sent, soonest first.
class MyViewingsPage extends StatelessWidget {
  const MyViewingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MyViewingsCubit(context.read<ViewingRepository>())..load(),
      child: BlocConsumer<MyViewingsCubit, MyViewingsState>(
        listenWhen: (a, b) =>
            b.errorMessage != null && b.status != RequestStatus.failure,
        listener: (context, state) =>
            showAppSnackBar(context, state.errorMessage!, isError: true),
        builder: (context, state) {
          final cubit = context.read<MyViewingsCubit>();
          return Scaffold(
            appBar: const ImukaAppBar(title: 'My viewings'),
            body: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: context.palette.ink,
                onRefresh: cubit.load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ResponsiveCenter(child: _content(context, state, cubit)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    MyViewingsState state,
    MyViewingsCubit cubit,
  ) {
    if (state.status == RequestStatus.loading && state.viewings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.status == RequestStatus.failure) {
      return EmptyState(
        icon: LucideIcons.wifiOff,
        title: 'Couldn\'t load viewings',
        message: state.errorMessage ?? 'Please try again.',
        actionLabel: 'Retry',
        onAction: cubit.load,
      );
    }
    if (state.viewings.isEmpty) {
      return EmptyState(
        icon: LucideIcons.calendar,
        title: 'No viewings yet',
        message: 'Open a verified home and tap "Contact owner" to book one.',
        actionLabel: 'Find homes',
        onAction: () => context.go(AppRoutes.search),
      );
    }
    return Column(
      children: [
        for (final viewing in state.viewings)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ViewingCard(
              viewing: viewing,
              onCancel: () async {
                final confirmed = await confirmDialog(
                  context: context,
                  title: 'Cancel this viewing?',
                  message:
                      '${viewing.ownerName} will be told you can\'t make it.',
                  confirmLabel: 'Cancel viewing',
                );
                if (confirmed) cubit.cancel(viewing.id);
              },
            ),
          ),
      ],
    );
  }
}

class _ViewingCard extends StatelessWidget {
  const _ViewingCard({required this.viewing, required this.onCancel});

  final ViewingRequest viewing;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cancelled = viewing.status == ViewingStatus.cancelled;
    final when =
        '${Formatters.longDate(viewing.scheduledAt)} · '
        '${DateFormat('HH:mm').format(viewing.scheduledAt)}';
    return AppCard(
      onTap: () => context.push(AppRoutes.property(viewing.propertyId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  viewing.propertyTitle,
                  style: context.text.titleMedium,
                ),
              ),
              StatusBadge(
                label: switch (viewing.status) {
                  ViewingStatus.requested => 'Requested',
                  ViewingStatus.confirmed => 'Confirmed',
                  ViewingStatus.cancelled => 'Cancelled',
                },
                tone: cancelled ? BadgeTone.neutral : BadgeTone.warning,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(when, style: context.text.titleSmall),
          Text(
            'With ${viewing.ownerName} · via ${viewing.channel.label}',
            style: context.text.bodySmall,
          ),
          if (!cancelled)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: context.palette.danger,
                ),
                child: const Text('Cancel viewing'),
              ),
            ),
        ],
      ),
    );
  }
}
