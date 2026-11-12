import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';

/// Explains the three listing checks behind the "Verified" badge.
class HowWeVerifyPage extends StatelessWidget {
  const HowWeVerifyPage({super.key});

  static const _steps = [
    (
      LucideIcons.idCard,
      '1  Owner identity',
      'Owners and agents share their National ID (Indangamuntu) and phone '
          'number. We confirm both.',
    ),
    (
      LucideIcons.fileText,
      '2  Proof of ownership',
      'We check the ownership document or the owner\'s written '
          'authorization for agents.',
    ),
    (
      LucideIcons.mapPin,
      '3  On-site check',
      'Photos, size and exact address are confirmed at the property in '
          'Kigali.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: const ImukaAppBar(title: 'How we verify'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: PageBody(
          children: [
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: p.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.shieldCheck, color: p.onSuccess),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Every listing is checked\nbefore it goes live',
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: 20),
            for (final (icon, title, body) in _steps) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.muted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(icon: icon, dark: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.text.titleSmall),
                          const SizedBox(height: 4),
                          Text(body, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const StatusBadge.verified(),
                const SizedBox(width: 12),
                Text('All 3 checks passed', style: context.text.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const StatusBadge.pending(),
                const SizedBox(width: 12),
                Text(
                  'Documents still in review',
                  style: context.text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const InfoPanel(
              outlined: true,
              icon: LucideIcons.info,
              title: 'Stay safe',
              message:
                  'Never pay a deposit before viewing. Always get a '
                  'signed agreement and a receipt.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          PrimaryButton(
            label: 'Back to listing',
            trailingIcon: null,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
