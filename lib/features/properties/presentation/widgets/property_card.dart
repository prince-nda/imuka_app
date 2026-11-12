import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/layout.dart';
import '../../domain/entities/property.dart';

/// Listing card: photo, verification badge, title, area, price and rating.
class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.property, this.onTap});

  final Property property;

  /// Defaults to opening the property details.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label:
          '${property.title}, ${property.subtitle}, '
          '${Formatters.rwf(property.monthlyRent)} per month, '
          '${property.isVerified ? 'verified' : 'verification pending'}',
      button: true,
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap ?? () => context.push(AppRoutes.property(property.id)),
        child: Row(
          children: [
            Hero(
              tag: 'property-image-${property.id}',
              child: RoundedImage(
                asset: property.imageAsset,
                semanticLabel: property.title,
                width: 100,
                height: 118,
                radius: 14,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  property.isVerified
                      ? const StatusBadge.verified()
                      : const StatusBadge.pending(),
                  const SizedBox(height: 8),
                  Text(
                    property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              text: Formatters.rwf(property.monthlyRent),
                              style: context.text.titleMedium?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                TextSpan(
                                  text: ' /mo',
                                  style: context.text.bodySmall?.copyWith(
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RatingLabel(rating: property.rating),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer-free placeholder shown while listings load.
class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: p.muted,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          bar(100, 118),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(70, 22),
                const SizedBox(height: 10),
                bar(double.infinity, 16),
                const SizedBox(height: 8),
                bar(120, 12),
                const SizedBox(height: 14),
                bar(140, 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
