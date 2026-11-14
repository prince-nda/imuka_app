import 'dart:math' as math;

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
import '../../../properties/domain/entities/landmark.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/services/compare_insights.dart';
import '../../../properties/presentation/cubit/property_search_cubit.dart';
import '../cubit/shortlist_cubit.dart';

/// Shortlist tab: saved homes side by side.
class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    final shortlist = context.watch<ShortlistCubit>().state;
    final search = context.watch<PropertySearchCubit>().state;
    final homes = [for (final id in shortlist.ids) ?search.byId(id)];
    final landmark = search.filter.landmark;
    final best = CompareInsights.bestMatch(homes, landmark);
    final loading =
        shortlist.status == RequestStatus.loading ||
        search.status == RequestStatus.loading;

    return Scaffold(
      appBar: ImukaAppBar(
        title: 'Compare homes',
        action: CircleIconButton(
          icon: LucideIcons.plus,
          tooltip: 'Add a home',
          onPressed: () => context.go(AppRoutes.search),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: homes.isEmpty
            ? Center(
                child: loading
                    ? const CircularProgressIndicator()
                    : EmptyState(
                        icon: LucideIcons.bookmark,
                        title: 'Your shortlist is empty',
                        message:
                            'Tap the bookmark on any home to compare '
                            'it here side by side.',
                        actionLabel: 'Find homes',
                        onAction: () => context.go(AppRoutes.search),
                      ),
              )
            : PageBody(
                children: [
                  _CompareTable(homes: homes, best: best, landmark: landmark),
                  const SizedBox(height: 20),
                  if (best != null)
                    PrimaryButton(
                      label: 'Contact ${best.neighbourhood} owner',
                      onPressed: () =>
                          context.push(AppRoutes.contactOwner(best.id)),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'Best match = the verified home closest to '
                    '${landmark.name}. Tap a home for more options.',
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({
    required this.homes,
    required this.best,
    required this.landmark,
  });

  final List<Property> homes;
  final Property? best;
  final Landmark landmark;

  static const _labelWidth = 84.0;
  static const _minColumnWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, Widget Function(Property))>[
      (
        'Rent / month',
        (h) => _value(context, Formatters.rwfShort(h.monthlyRent)),
      ),
      ('Size', (h) => _value(context, '${h.sizeSqm} m²')),
      ('Bedrooms', (h) => _value(context, '${h.bedrooms}')),
      (
        'Bathrooms',
        (h) => _value(context, h.sharedBathroom ? 'Shared' : '${h.bathrooms}'),
      ),
      (
        'To work',
        (h) => _value(
          context,
          Formatters.km(h.location.distanceTo(landmark.location)),
        ),
      ),
      ('Deposit', (h) => _value(context, h.depositLabel)),
      ('Meters', (h) => _value(context, h.ownMeters ? 'Own' : 'Shared')),
      (
        'Verified',
        (h) => h.isVerified
            ? const StatusBadge.verified(label: 'Yes')
            : const StatusBadge.pending(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = math.max(
          _minColumnWidth,
          (constraints.maxWidth - _labelWidth) / homes.length,
        );
        final columnWidths = {
          0: const FixedColumnWidth(_labelWidth),
          for (var i = 0; i < homes.length; i++)
            i + 1: FixedColumnWidth(columnWidth),
        };
        final border = TableBorder(
          horizontalInside: BorderSide(color: context.palette.border),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Table(
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      for (final h in homes)
                        _HomeHeader(home: h, isBest: h == best),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Table(
                columnWidths: columnWidths,
                border: border,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  for (final (label, cell) in rows)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(label, style: context.text.bodySmall),
                        ),
                        for (final h in homes) Center(child: cell(h)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _value(BuildContext context, String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: context.text.titleSmall?.copyWith(fontSize: 13.5),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.home, required this.isBest});

  final Property home;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${home.title}${isBest ? ', best match' : ''}. '
          'Tap for options.',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _showOptions(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  RoundedImage(
                    asset: home.imageAsset,
                    semanticLabel: home.title,
                    width: 84,
                    height: 64,
                    radius: 14,
                  ),
                  if (isBest)
                    const Positioned(
                      top: -8,
                      child: StatusBadge(
                        label: 'Best match',
                        tone: BadgeTone.highlight,
                        compact: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                home.neighbourhood,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall,
              ),
              Text(home.type.label, style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final shortlist = context.read<ShortlistCubit>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(home.title, style: sheetContext.text.titleLarge),
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(LucideIcons.house),
              title: const Text('View details'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.property(home.id));
              },
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(LucideIcons.messageSquare),
              title: const Text('Contact owner'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(AppRoutes.contactOwner(home.id));
              },
            ),
            ListTile(
              minTileHeight: 56,
              leading: Icon(LucideIcons.trash2, color: context.palette.danger),
              title: Text(
                'Remove from shortlist',
                style: TextStyle(color: context.palette.danger),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                shortlist.toggle(home.id);
                showAppSnackBar(
                  context,
                  '${home.title} removed',
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => shortlist.add(home.id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
