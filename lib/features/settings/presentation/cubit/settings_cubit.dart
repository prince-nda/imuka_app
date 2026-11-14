import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../move/domain/entities/payment.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Holds user preferences; every change is written through to storage.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(_repository.load());

  final SettingsRepository _repository;

  void setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));

  void setVerifiedOnlyByDefault(bool value) =>
      _update(state.copyWith(verifiedOnlyByDefault: value));

  void setPreferredPayment(PaymentMethod method) =>
      _update(state.copyWith(preferredPayment: method));

  void setMoveReminders(bool value) =>
      _update(state.copyWith(moveReminders: value));

  void _update(AppSettings next) {
    emit(next);
    _repository.save(next);
  }
}
