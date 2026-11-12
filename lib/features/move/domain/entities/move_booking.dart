import 'package:equatable/equatable.dart';

import 'mover.dart';
import 'payment.dart';

/// The five steps shown as "Step x of 5" on My move.
enum MoveStage {
  findHome('Find a home'),
  planMove('Plan your move'),
  moversBooked('Movers booked'),
  movingDay('Moving day'),
  completed('Move complete');

  const MoveStage(this.label);
  final String label;

  int get step => index + 1;
  static int get totalSteps => values.length;
}

/// The saved booking state of the user's move.
class MoveBooking extends Equatable {
  const MoveBooking({
    this.stage = MoveStage.planMove,
    this.mover,
    this.quote,
    this.receipt,
    this.rating = 0,
  });

  final MoveStage stage;
  final Mover? mover;

  /// Locked-in price at booking time.
  final int? quote;
  final PaymentReceipt? receipt;
  final int rating;

  @override
  List<Object?> get props => [stage, mover, quote, receipt, rating];
}
