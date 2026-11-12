import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/map_canvas.dart';
import '../../../shortlist/presentation/cubit/shortlist_cubit.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../cubit/property_details_cubit.dart';
import '../cubit/property_search_cubit.dart';
import '../widgets/property_icons.dart';

class PropertyDetailsPage extends StatelessWidget {
  const PropertyDetailsPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Reuse the listing already loaded by the search when possible.
      create: (context) => PropertyDetailsCubit(
        context.read<PropertyRepository>(),
        initial: context.read<PropertySearchCubit>().state.byId(propertyId),
      )..load(propertyId),
      child: BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
        builder: (context, state) {
          final property = state.property;
          if (property != null) return _DetailsView(property: property);
          return Scaffold(
            appBar: const ImukaAppBar(),
            body: state.status == RequestStatus.failure
                ? EmptyState(
                    icon: LucideIcons.searchX,
                    title: 'Listing not found',
                    message: 'This home may have been rented or removed.',
                    actionLabel: 'Find another home',
                    onAction: () => context.go(AppRoutes.search),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final landmark = context.select(
      (PropertySearchCubit c) => c.state.filter.landmark,
    );
    final distance = property.location.distanceTo(landmark.location);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageBody(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            8,
            AppTheme.pagePadding,
            24,
          ),
          children: [
            _Gallery(property: property),
            const SizedBox(height: 16),
            Text(property.title, style: context.text.headlineSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 15, color: p.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    property.fullAddress,
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: Formatters.rwf(property.monthlyRent),
                      style: context.text.headlineMedium,
                      children: [
                        TextSpan(
                          text: '  /month',
                          style: context.text.bodyMedium?.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                RatingLabel(
                  rating: property.rating,
                  reviews: property.reviewCount,
                  large: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _KeyStats(property: property),
            const SizedBox(height: 16),
            _VerificationCard(property: property),
            const SectionTitle('Property information'),
            _PropertyInfo(property: property),
            const SectionTitle('Facilities'),
            _Facilities(facilities: property.facilities),
            const SectionTitle('Location'),
            _LocationPreview(street: property.street),
            const SizedBox(height: 12),
            AppCard(
              color: p.muted,
              borderColor: Colors.transparent,
              radius: AppTheme.radiusMd,
              child: Row(
                children: [
                  const Icon(LucideIcons.route, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Formatters.km(distance)} from ${landmark.name}',
                          style: context.text.titleSmall,
                        ),
                        Text(
                          property.transitNote,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OwnerCard(owner: property.owner),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlineAppButton(
                  label: 'Compare',
                  leadingIcon: LucideIcons.arrowUpDown,
                  height: 56,
                  onPressed: () async {
                    await context.read<ShortlistCubit>().add(property.id);
                    if (context.mounted) context.go(AppRoutes.shortlist);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: PrimaryButton(
                  label: 'Contact owner',
                  onPressed: () =>
                      context.push(AppRoutes.contactOwner(property.id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final saved = context.select(
      (ShortlistCubit c) => c.state.contains(property.id),
    );
    final height = (MediaQuery.sizeOf(context).height * 0.34).clamp(
      200.0,
      300.0,
    );
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'property-image-${property.id}',
            child: RoundedImage(
              asset: property.imageAsset,
              semanticLabel: 'Photo of ${property.title}',
              radius: 28,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: CircleIconButton(
              icon: LucideIcons.chevronLeft,
              tooltip: 'Back',
              showBorder: false,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: CircleIconButton(
              icon: saved ? Icons.bookmark_rounded : LucideIcons.bookmark,
              tooltip: saved ? 'Remove from shortlist' : 'Save to shortlist',
              showBorder: false,
              onPressed: () => _toggleSaved(context),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: property.isVerified
                ? const StatusBadge(
                    label: 'Verified listing',
                    icon: LucideIcons.shieldCheck,
                    tone: BadgeTone.successOutline,
                  )
                : const StatusBadge.pending(label: 'Verification pending'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSaved(BuildContext context) async {
    final cubit = context.read<ShortlistCubit>();
    final nowSaved = await cubit.toggle(property.id);
    if (!context.mounted) return;
    final error = cubit.state.errorMessage;
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
      return;
    }
    showAppSnackBar(
      context,
      nowSaved ? 'Saved to your shortlist' : 'Removed from your shortlist',
      action: nowSaved
          ? SnackBarAction(
              label: 'Compare',
              onPressed: () => context.go(AppRoutes.shortlist),
            )
          : null,
    );
  }
}

class _KeyStats extends StatelessWidget {
  const _KeyStats({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (LucideIcons.bedDouble, '${property.bedrooms}', 'Bedrooms'),
      (
        LucideIcons.bath,
        property.sharedBathroom ? 'Shared' : '${property.bathrooms}',
        'Bathrooms',
      ),
      (LucideIcons.scan, '${property.sizeSqm} m²', 'Size'),
    ];
    return Row(
      children: [
        for (final (i, (icon, value, label)) in stats.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.palette.muted,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(height: 10),
                  Text(value, style: context.text.titleLarge),
                  Text(label, style: context.text.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final checks = property.checks;
    final verified = checks.isVerified;
    final accent = verified ? p.success : p.warning;
    final items = [
      ('Owner identity confirmed (National ID)', checks.ownerIdentity),
      ('Ownership document checked', checks.ownershipDocument),
      ('Photos & location confirmed on site', checks.onSiteCheck),
    ];
    return AppCard(
      borderColor: accent,
      borderWidth: 1.5,
      onTap: () => context.push(AppRoutes.howWeVerify(property.id)),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: verified ? p.success : p.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  verified ? LucideIcons.shieldCheck : LucideIcons.clock,
                  color: verified ? p.onSuccess : p.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verified
                          ? 'Verified by Imuka'
                          : 'Verification in progress',
                      style: context.text.titleMedium,
                    ),
                    Text(
                      checks.lastCheckedOn != null
                          ? 'Last checked ${Formatters.date(checks.lastCheckedOn!)}'
                          : verified
                          ? 'All checks passed'
                          : 'Some documents are still in review',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: p.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          for (final (label, passed) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    passed ? LucideIcons.check : LucideIcons.clock,
                    size: 18,
                    color: passed ? p.success : p.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      passed ? label : '$label — pending',
                      style: context.text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PropertyInfo extends StatelessWidget {
  const _PropertyInfo({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Type', property.type.label),
      ('Furnishing', property.furnishing),
      ('Floor', property.floor),
      ('Lease', 'Min. ${property.minLeaseMonths} months'),
      (
        'Deposit',
        '${property.depositLabel} (${Formatters.rwf(property.depositAmount)})',
      ),
      (
        'Utilities',
        property.ownMeters ? 'Own Cash Power & water meter' : 'Shared meters',
      ),
      ('Available from', Formatters.date(property.availableFrom)),
    ];
    return Column(
      children: [
        for (final (i, (label, value)) in rows.indexed)
          KeyValueRow(
            label: label,
            value: value,
            showDivider: i < rows.length - 1,
          ),
      ],
    );
  }
}

class _Facilities extends StatelessWidget {
  const _Facilities({required this.facilities});

  final List<Facility> facilities;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        for (final facility in facilities)
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: p.muted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    facility.icon,
                    size: 22,
                    color: facility == Facility.security
                        ? p.success
                        : p.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  facility.label,
                  textAlign: TextAlign.center,
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.street});

  final String street;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: SizedBox(
        height: 150,
        child: CityBlocksMap(
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.card, width: 3),
                  ),
                  child: Icon(LucideIcons.mapPin, color: p.onInk, size: 18),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: StatusBadge(
                  label: street,
                  tone: BadgeTone.neutral,
                  compact: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner});

  final PropertyOwner owner;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: p.ink,
            child: Text(
              Formatters.initials(owner.name),
              style: context.text.titleSmall?.copyWith(color: p.onInk),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(owner.name, style: context.text.titleSmall),
                Text(
                  'Owner · replies in ~${owner.typicalReplyMinutes} min',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          if (owner.idVerified)
            const StatusBadge.verified(label: 'ID verified')
          else
            const StatusBadge.pending(label: 'ID pending'),
        ],
      ),
    );
  }
}
