import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/pickers.dart';
import '../../../../core/widgets/selectors.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../move/domain/entities/payment.dart';
import '../../domain/entities/app_settings.dart';
import '../cubit/settings_cubit.dart';

/// Profile, saved preferences and sign-out.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      appBar: const ImukaAppBar(title: 'Settings'),
      body: SafeArea(
        top: false,
        child: PageBody(
          children: [
            if (user != null) _ProfileCard(user: user),
            const SizedBox(height: 12),
            NavListTile(
              icon: LucideIcons.calendar,
              title: 'My viewings',
              subtitle: 'Requests you sent to owners',
              onTap: () => context.push(AppRoutes.myViewings),
            ),
            const SectionTitle('Appearance'),
            SegmentedSelector<ThemeMode>(
              options: ThemeMode.values,
              selected: settings.themeMode,
              labelOf: (m) => switch (m) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              },
              onChanged: cubit.setThemeMode,
            ),
            const SectionTitle('Preferences'),
            _SwitchRow(
              icon: LucideIcons.shieldCheck,
              title: 'Verified listings only',
              subtitle: 'Start every search with only verified homes',
              value: settings.verifiedOnlyByDefault,
              onChanged: cubit.setVerifiedOnlyByDefault,
            ),
            _SwitchRow(
              icon: LucideIcons.bell,
              title: 'Move reminders',
              subtitle: 'Reminders about your moving day and tasks',
              value: settings.moveReminders,
              onChanged: cubit.setMoveReminders,
            ),
            const SizedBox(height: 4),
            _PaymentPreference(settings: settings),
            const SizedBox(height: 8),
            Text(
              'Preferences are saved on this device and restored when you '
              'reopen Imuka.',
              style: context.text.bodySmall,
            ),
            const SectionTitle('Account'),
            OutlineAppButton(
              label: 'Log out',
              leadingIcon: LucideIcons.logOut,
              onPressed: () async {
                final authCubit = context.read<AuthCubit>();
                final confirmed = await confirmDialog(
                  context: context,
                  title: 'Log out of Imuka?',
                  message:
                      'Your shortlist and move plan stay saved to your '
                      'account.',
                  confirmLabel: 'Log out',
                );
                if (confirmed) authCubit.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final contact = user.phone.isNotEmpty
        ? Formatters.phone(user.phone)
        : (user.email ?? '');
    return AppCard(
      radius: AppTheme.radiusLg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: p.ink,
            child: Text(
              Formatters.initials(user.fullName.isEmpty ? '?' : user.fullName),
              style: context.text.titleMedium?.copyWith(color: p.onInk),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Add your name' : user.fullName,
                  style: context.text.titleMedium,
                ),
                Text(contact, style: context.text.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusBadge(
                      label: user.role == UserRole.mover
                          ? 'Moving'
                          : 'Landlord',
                      tone: BadgeTone.neutral,
                      compact: true,
                    ),
                    StatusBadge(
                      label: switch (user.signInMethod) {
                        SignInMethod.email => 'Email account',
                        SignInMethod.google => 'Google account',
                      },
                      tone: BadgeTone.neutral,
                      compact: true,
                    ),
                    if (user.emailVerified)
                      const StatusBadge(
                        label: 'Email verified',
                        icon: LucideIcons.shieldCheck,
                        compact: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: LucideIcons.pencil,
            tooltip: 'Edit name',
            onPressed: () => _editName(context),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initial: user.fullName),
    );
    if (name == null || !context.mounted) return;
    final error = await authCubit.updateFullName(name);
    if (!context.mounted) return;
    showAppSnackBar(context, error ?? 'Name updated', isError: error != null);
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});

  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

/// Stateful only to own the text controller and form key.
class _EditNameDialogState extends State<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'First and last name'),
          validator: Validators.fullName,
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            IconTile(icon: icon, size: 40, iconSize: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  Text(subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _PaymentPreference extends StatelessWidget {
  const _PaymentPreference({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const IconTile(icon: LucideIcons.wallet, size: 40, iconSize: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Preferred payment', style: context.text.titleSmall),
        ),
        SizedBox(
          width: 170,
          child: SelectField(
            icon: LucideIcons.creditCard,
            value: settings.preferredPayment.label,
            semanticLabel: 'Preferred payment method',
            onTap: () async {
              final cubit = context.read<SettingsCubit>();
              final method = await showOptionsSheet<PaymentMethod>(
                context: context,
                title: 'Preferred payment',
                options: PaymentMethod.values,
                selected: settings.preferredPayment,
                labelOf: (m) => m.label,
                subtitleOf: (m) => m.description,
              );
              if (method != null) cubit.setPreferredPayment(method);
            },
          ),
        ),
      ],
    );
  }
}
