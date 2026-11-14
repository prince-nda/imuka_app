import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/features/move/domain/entities/payment.dart';
import 'package:imuka/features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'package:imuka/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('preferences survive an app restart', () async {
    final prefs = await SharedPreferences.getInstance();
    SharedPrefsSettingsRepository(prefs);

    final first = SettingsCubit(SharedPrefsSettingsRepository(prefs))
      ..setThemeMode(ThemeMode.dark)
      ..setVerifiedOnlyByDefault(false)
      ..setPreferredPayment(PaymentMethod.airtelMoney)
      ..setMoveReminders(false);
    await Future<void>.delayed(Duration.zero);
    await first.close();

    // A new cubit simulates relaunching the app.
    final relaunched = SettingsCubit(SharedPrefsSettingsRepository(prefs));
    expect(relaunched.state.themeMode, ThemeMode.dark);
    expect(relaunched.state.verifiedOnlyByDefault, isFalse);
    expect(relaunched.state.preferredPayment, PaymentMethod.airtelMoney);
    expect(relaunched.state.moveReminders, isFalse);
  });

  test('falls back to defaults for missing or outdated values', () async {
    SharedPreferences.setMockInitialValues({
      SharedPrefsSettingsRepository.paymentKey: 'bitcoin',
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SharedPrefsSettingsRepository(prefs).load();
    expect(settings.preferredPayment, PaymentMethod.mtnMomo);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.verifiedOnlyByDefault, isTrue);
  });
}
