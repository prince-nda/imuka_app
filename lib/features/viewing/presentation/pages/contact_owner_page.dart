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
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/selectors.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/repositories/property_repository.dart';
import '../../../properties/presentation/cubit/property_details_cubit.dart';
import '../../../properties/presentation/cubit/property_search_cubit.dart';
import '../../domain/entities/viewing_request.dart';
import '../../domain/repositories/viewing_repository.dart';
import '../cubit/contact_owner_cubit.dart';

class ContactOwnerPage extends StatelessWidget {
  const ContactOwnerPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertyDetailsCubit(
        context.read<PropertyRepository>(),
        initial: context.read<PropertySearchCubit>().state.byId(propertyId),
      )..load(propertyId),
      child: BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
        builder: (context, state) {
          final property = state.property;
          if (property == null) {
            return Scaffold(
              appBar: const ImukaAppBar(title: 'Contact owner'),
              body: state.status == RequestStatus.failure
                  ? const EmptyState(
                      icon: LucideIcons.searchX,
                      title: 'Listing not found',
                      message: 'This home may have been rented or removed.',
                    )
                  : const Center(child: CircularProgressIndicator()),
            );
          }
          return BlocProvider(
            create: (context) =>
                ContactOwnerCubit(context.read<ViewingRepository>(), property),
            child: _ContactOwnerView(property: property),
          );
        },
      ),
    );
  }
}

class _ContactOwnerView extends StatefulWidget {
  const _ContactOwnerView({required this.property});

  final Property property;

  @override
  State<_ContactOwnerView> createState() => _ContactOwnerViewState();
}

/// Stateful only to own the message controller.
class _ContactOwnerViewState extends State<_ContactOwnerView> {
  late final TextEditingController _message;

  @override
  void initState() {
    super.initState();
    final from = context.read<PropertySearchCubit>().state.filter.from;
    _message = TextEditingController(
      text:
          'Hello, I am moving from ${from.label} and can visit this '
          'weekend. Is the ${widget.property.type.label.toLowerCase()} '
          'still available?',
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return BlocConsumer<ContactOwnerCubit, ContactOwnerState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == RequestStatus.failure) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
        if (state.status == RequestStatus.success && state.created != null) {
          context.pushReplacement(
            AppRoutes.viewingRequested,
            extra: state.created,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ContactOwnerCubit>();
        return Scaffold(
          appBar: const ImukaAppBar(title: 'Contact owner'),
          body: SafeArea(
            top: false,
            bottom: false,
            child: PageBody(
              children: [
                _ListingSummary(property: property),
                const SectionTitle('Reach out'),
                Row(
                  children: [
                    for (final (i, channel)
                        in ContactChannel.values.indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _ChannelTile(
                          channel: channel,
                          selected: state.channel == channel,
                          onTap: () => cubit.selectChannel(channel),
                        ),
                      ),
                    ],
                  ],
                ),
                const SectionTitle('Book a viewing'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (final date in state.dates) ...[
                        _DateChip(
                          date: date,
                          selected: date == state.selectedDate,
                          onTap: () => cubit.selectDate(date),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PillRow(
                  children: [
                    for (final slot in ContactOwnerCubit.timeSlots)
                      ChoicePill(
                        label: slot,
                        selected: slot == state.selectedSlot,
                        onTap: () => cubit.selectSlot(slot),
                      ),
                  ],
                ),
                const FieldLabel('Message (optional)'),
                AppTextField(
                  controller: _message,
                  maxLines: 4,
                  hint: 'Introduce yourself and ask a question',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v ?? '').length > 500
                      ? 'Keep your message under 500 characters.'
                      : null,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomActionBar(
            children: [
              PrimaryButton(
                label: 'Request viewing',
                isLoading: state.status.isLoading,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  cubit.submit(_message.text);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListingSummary extends StatelessWidget {
  const _ListingSummary({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      color: p.muted,
      borderColor: Colors.transparent,
      radius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          RoundedImage(
            asset: property.imageAsset,
            semanticLabel: property.title,
            width: 56,
            height: 56,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.title, style: context.text.titleSmall),
                Text(
                  '${Formatters.rwf(property.monthlyRent)} /mo',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: p.ink,
                      child: Text(
                        property.owner.name[0],
                        style: context.text.labelSmall?.copyWith(
                          color: p.onInk,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${property.owner.name} · Owner',
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.channel,
    required this.selected,
    required this.onTap,
  });

  final ContactChannel channel;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (channel) {
    ContactChannel.call => LucideIcons.phone,
    ContactChannel.whatsapp => LucideIcons.messageSquare,
    ContactChannel.inAppChat => LucideIcons.fileText,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      label: 'Contact by ${channel.label}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        radius: AppTheme.radiusMd,
        borderColor: selected ? p.ink : p.border,
        borderWidth: selected ? 1.5 : 1,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        child: Column(
          children: [
            Icon(_icon, size: 22),
            const SizedBox(height: 8),
            Text(
              channel.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onInk : p.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      label: Formatters.longDate(date),
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        radius: AppTheme.radiusMd,
        color: selected ? p.ink : p.card,
        borderColor: selected ? p.ink : p.border,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Text(
              Formatters.weekday(date),
              style: context.text.bodySmall?.copyWith(
                color: selected ? p.onInk.withValues(alpha: 0.8) : null,
              ),
            ),
            Text(
              Formatters.dayMonth(date),
              style: context.text.titleSmall?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
