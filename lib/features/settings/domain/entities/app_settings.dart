import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../../move/domain/entities/payment.dart';

/// User preferences persisted on the device and restored on launch.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.verifiedOnlyByDefault = true,
    this.preferredPayment = PaymentMethod.mtnMomo,
    this.moveReminders = true,
  });

  final ThemeMode themeMode;

  /// Whether new searches start with "Verified listings only" switched on.
  final bool verifiedOnlyByDefault;

  /// Pre-selected method on the payment screen.
  final PaymentMethod preferredPayment;

  /// Whether to remind the user about upcoming move tasks.
  final bool moveReminders;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? verifiedOnlyByDefault,
    PaymentMethod? preferredPayment,
    bool? moveReminders,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    verifiedOnlyByDefault: verifiedOnlyByDefault ?? this.verifiedOnlyByDefault,
    preferredPayment: preferredPayment ?? this.preferredPayment,
    moveReminders: moveReminders ?? this.moveReminders,
  );

  @override
  List<Object?> get props => [
    themeMode,
    verifiedOnlyByDefault,
    preferredPayment,
    moveReminders,
  ];
}
