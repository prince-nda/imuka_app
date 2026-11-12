import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/request_status.dart';
import '../../domain/entities/move_booking.dart';
import '../../domain/entities/move_plan.dart';
import '../../domain/entities/mover.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/move_repositories.dart';

export '../../domain/entities/move_booking.dart' show MoveStage;

class MoveBookingState extends Equatable {
  const MoveBookingState({
    required this.paymentMethod,
    this.stage = MoveStage.planMove,
    this.movers = const [],
    this.moversStatus = RequestStatus.initial,
    this.moversVehicle,
    this.selectedMoverId,
    this.bookedMover,
    this.paymentStatus = RequestStatus.initial,
    this.receipt,
    this.rating = 0,
    this.errorMessage,
  });

  final MoveStage stage;
  final List<Mover> movers;
  final RequestStatus moversStatus;

  /// Vehicle size [movers] were loaded for.
  final VehicleType? moversVehicle;
  final String? selectedMoverId;
  final Mover? bookedMover;
  final PaymentMethod paymentMethod;
  final RequestStatus paymentStatus;
  final PaymentReceipt? receipt;
  final int rating;
  final String? errorMessage;

  Mover? get selectedMover {
    for (final m in movers) {
      if (m.id == selectedMoverId) return m;
    }
    return null;
  }

  MoveBookingState copyWith({
    MoveStage? stage,
    List<Mover>? movers,
    RequestStatus? moversStatus,
    VehicleType? moversVehicle,
    String? Function()? selectedMoverId,
    Mover? bookedMover,
    PaymentMethod? paymentMethod,
    RequestStatus? paymentStatus,
    PaymentReceipt? receipt,
    int? rating,
    String? errorMessage,
  }) => MoveBookingState(
    stage: stage ?? this.stage,
    movers: movers ?? this.movers,
    moversStatus: moversStatus ?? this.moversStatus,
    moversVehicle: moversVehicle ?? this.moversVehicle,
    selectedMoverId: selectedMoverId == null
        ? this.selectedMoverId
        : selectedMoverId(),
    bookedMover: bookedMover ?? this.bookedMover,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    receipt: receipt ?? this.receipt,
    rating: rating ?? this.rating,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    stage,
    movers,
    moversStatus,
    moversVehicle,
    selectedMoverId,
    bookedMover,
    paymentMethod,
    paymentStatus,
    receipt,
    rating,
    errorMessage,
  ];
}

/// Mover comparison, booking, payment and rating for the current move.
class MoveBookingCubit extends Cubit<MoveBookingState> {
  MoveBookingCubit(this._repository, {required PaymentMethod paymentMethod})
    : super(MoveBookingState(paymentMethod: paymentMethod));

  final MoverRepository _repository;

  /// Restores the saved booking for the signed-in user.
  Future<void> restore() async {
    try {
      final booking = await _repository.fetchBooking();
      if (booking == null) return;
      emit(
        state.copyWith(
          stage: booking.stage,
          bookedMover: booking.mover,
          receipt: booking.receipt,
          paymentMethod: booking.receipt?.method,
          rating: booking.rating,
        ),
      );
    } catch (_) {
      emit(state.copyWith(errorMessage: 'We couldn\'t load your booking.'));
    }
  }

  /// Clears the booking when the user logs out.
  void reset() => emit(MoveBookingState(paymentMethod: state.paymentMethod));

  /// Loads movers for [vehicle] and pre-selects the one chosen by
  /// [preselect] (the best value mover).
  Future<void> loadMovers(
    VehicleType vehicle, {
    String? Function(List<Mover>)? preselect,
  }) async {
    if (state.moversVehicle == vehicle &&
        state.moversStatus == RequestStatus.success) {
      return;
    }
    emit(
      state.copyWith(
        moversStatus: RequestStatus.loading,
        moversVehicle: vehicle,
        movers: const [],
        selectedMoverId: () => null,
      ),
    );
    try {
      final movers = await _repository.fetchMovers(vehicle);
      if (state.moversVehicle != vehicle) return; // user switched again
      emit(
        state.copyWith(
          movers: movers,
          moversStatus: RequestStatus.success,
          selectedMoverId: () => preselect?.call(movers),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          moversStatus: RequestStatus.failure,
          errorMessage: 'We couldn\'t load movers. Pull down to retry.',
        ),
      );
    }
  }

  void selectMover(String id) =>
      emit(state.copyWith(selectedMoverId: () => id));

  /// Locks in the selected mover at [quote] and saves the booking.
  /// Booking again (e.g. after a cancelled move) starts a fresh booking.
  Future<bool> bookSelected(int quote) async {
    final mover = state.selectedMover;
    if (mover == null) {
      emit(state.copyWith(errorMessage: 'Choose a mover first.'));
      return false;
    }
    final previous = state;
    emit(
      MoveBookingState(
        paymentMethod: state.paymentMethod,
        stage: MoveStage.moversBooked,
        movers: state.movers,
        moversStatus: state.moversStatus,
        moversVehicle: state.moversVehicle,
        selectedMoverId: state.selectedMoverId,
        bookedMover: mover,
      ),
    );
    try {
      await _repository.bookMover(mover: mover, quote: quote);
      return true;
    } catch (_) {
      emit(
        previous.copyWith(
          errorMessage: 'We couldn\'t book ${mover.name}. Please try again.',
        ),
      );
      return false;
    }
  }

  void startMovingDay() {
    if (state.stage.index < MoveStage.movingDay.index) {
      emit(state.copyWith(stage: MoveStage.movingDay));
      _repository.updateStage(MoveStage.movingDay).ignore();
    }
  }

  void selectPaymentMethod(PaymentMethod method) =>
      emit(state.copyWith(paymentMethod: method));

  Future<void> pay({required MovePlan plan, required int amount}) async {
    final mover = state.bookedMover;
    if (mover == null || state.paymentStatus.isLoading) return;
    emit(state.copyWith(paymentStatus: RequestStatus.loading));
    try {
      final receipt = await _repository.pay(
        mover: mover,
        plan: plan,
        amount: amount,
        method: state.paymentMethod,
      );
      emit(
        state.copyWith(
          paymentStatus: RequestStatus.success,
          receipt: receipt,
          stage: MoveStage.completed,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          paymentStatus: RequestStatus.failure,
          errorMessage:
              'Payment didn\'t go through. No money was taken — '
              'please try again.',
        ),
      );
    }
  }

  Future<void> rate(int stars) async {
    final mover = state.bookedMover;
    if (mover == null) return;
    emit(state.copyWith(rating: stars));
    await _repository.rateMover(mover.id, stars);
  }
}
