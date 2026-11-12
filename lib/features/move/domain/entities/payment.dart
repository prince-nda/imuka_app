import 'package:equatable/equatable.dart';

import 'mover.dart';
import 'move_plan.dart';

enum PaymentMethod {
  mtnMomo('MTN MoMo', 'Mobile money'),
  airtelMoney('Airtel Money', 'Mobile money'),
  card('Bank card', 'Visa or Mastercard');

  const PaymentMethod(this.label, this.description);
  final String label;
  final String description;

  bool get isMobileMoney => this != card;
}

/// Proof of a completed payment, released to the mover after the user
/// confirmed every item arrived.
class PaymentReceipt extends Equatable {
  const PaymentReceipt({
    required this.reference,
    required this.amount,
    required this.method,
    required this.moverName,
    required this.plan,
    required this.paidAt,
  });

  /// e.g. "IMK-4821".
  final String reference;
  final int amount;
  final PaymentMethod method;
  final String moverName;
  final MovePlan plan;
  final DateTime paidAt;

  factory PaymentReceipt.forMover({
    required String reference,
    required int amount,
    required PaymentMethod method,
    required Mover mover,
    required MovePlan plan,
    required DateTime paidAt,
  }) => PaymentReceipt(
    reference: reference,
    amount: amount,
    method: method,
    moverName: mover.name,
    plan: plan,
    paidAt: paidAt,
  );

  @override
  List<Object?> get props => [
    reference,
    amount,
    method,
    moverName,
    plan,
    paidAt,
  ];
}
