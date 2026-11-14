import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../move/domain/entities/payment.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Stores [AppSettings] as individual SharedPreferences keys.
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const themeModeKey = 'settings.themeMode';
  static const verifiedOnlyKey = 'settings.verifiedOnlyByDefault';
  static const paymentKey = 'settings.preferredPayment';
  static const remindersKey = 'settings.moveReminders';

  @override
  AppSettings load() {
    const defaults = AppSettings();
    return AppSettings(
      themeMode: _enumByName(
        ThemeMode.values,
        _prefs.getString(themeModeKey),
        defaults.themeMode,
      ),
      verifiedOnlyByDefault:
          _prefs.getBool(verifiedOnlyKey) ?? defaults.verifiedOnlyByDefault,
      preferredPayment: _enumByName(
        PaymentMethod.values,
        _prefs.getString(paymentKey),
        defaults.preferredPayment,
      ),
      moveReminders: _prefs.getBool(remindersKey) ?? defaults.moveReminders,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _prefs.setString(themeModeKey, settings.themeMode.name),
      _prefs.setBool(verifiedOnlyKey, settings.verifiedOnlyByDefault),
      _prefs.setString(paymentKey, settings.preferredPayment.name),
      _prefs.setBool(remindersKey, settings.moveReminders),
    ]);
  }

  /// Falls back to [fallback] if the stored name is missing or outdated.
  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
