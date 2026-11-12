import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';

/// First screen for signed-out users.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const _heroAsset = 'assets/images/kigali_hero.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            return landscape
                ? _LandscapeLayout(height: constraints.maxHeight)
                : _PortraitLayout(height: constraints.maxHeight);
          },
        ),
      ),
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height - AppTheme.pagePadding * 2,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoundedImage(
                asset: WelcomePage._heroAsset,
                semanticLabel: 'Aerial view of a Kigali neighbourhood',
                height: (height * 0.42).clamp(220, 420),
                radius: 28,
              ),
              const SizedBox(height: 24),
              const _Intro(),
              const Spacer(),
              const SizedBox(height: 24),
              const _Actions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: RoundedImage(
              asset: WelcomePage._heroAsset,
              semanticLabel: 'Aerial view of a Kigali neighbourhood',
              height: double.infinity,
              radius: 28,
            ),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_Intro(), SizedBox(height: 24), _Actions()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ImukaLogo(size: 36, showWordmark: true),
        const SizedBox(height: 16),
        Text(
          'Moving to Kigali,\nmade simple.',
          style: context.text.displaySmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Find verified homes, compare them side by side and plan your '
          'whole move — from Huye, Musanze, Rubavu or anywhere in Rwanda.',
          style: context.text.bodyMedium?.copyWith(
            color: context.palette.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: 'Get started',
          onPressed: () => context.push(AppRoutes.signup),
        ),
        const SizedBox(height: 8),
        LinkButton(
          label: 'I already have an account',
          onPressed: () => context.push(AppRoutes.login),
        ),
      ],
    );
  }
}
