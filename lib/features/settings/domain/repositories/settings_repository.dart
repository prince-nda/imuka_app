import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Reads saved preferences synchronously so the first frame already uses
  /// the right theme.
  AppSettings load();

  Future<void> save(AppSettings settings);
}
