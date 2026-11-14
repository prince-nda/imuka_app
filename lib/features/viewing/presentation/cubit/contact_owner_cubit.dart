import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../../../core/utils/request_status.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/viewing_request.dart';
import '../../domain/repositories/viewing_repository.dart';

class ContactOwnerState extends Equatable {
  const ContactOwnerState({
    required this.dates,
    required this.selectedDate,
    this.channel = ContactChannel.whatsapp,
    this.selectedSlot = ContactOwnerCubit.defaultSlot,
    this.status = RequestStatus.initial,
    this.errorMessage,
    this.created,
  });

  /// The next few days the owner accepts viewings on.
  final List<DateTime> dates;
  final DateTime selectedDate;
  final ContactChannel channel;

  /// Time of day as "HH:mm".
  final String selectedSlot;
  final RequestStatus status;
  final String? errorMessage;
  final ViewingRequest? created;

  DateTime get scheduledAt {
    final parts = selectedSlot.split(':').map(int.parse).toList();
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      parts[0],
      parts[1],
    );
  }

  ContactOwnerState copyWith({
    DateTime? selectedDate,
    ContactChannel? channel,
    String? selectedSlot,
    RequestStatus? status,
    String? errorMessage,
    ViewingRequest? created,
  }) => ContactOwnerState(
    dates: dates,
    selectedDate: selectedDate ?? this.selectedDate,
    channel: channel ?? this.channel,
    selectedSlot: selectedSlot ?? this.selectedSlot,
    status: status ?? this.status,
    errorMessage: errorMessage,
    created: created ?? this.created,
  );

  @override
  List<Object?> get props => [
    dates,
    selectedDate,
    channel,
    selectedSlot,
    status,
    errorMessage,
    created,
  ];
}

class ContactOwnerCubit extends Cubit<ContactOwnerState>
    with SafeEmit<ContactOwnerState> {
  ContactOwnerCubit(this._repository, this.property, {DateTime? today})
    : super(_initial(today ?? DateTime.now()));

  static const timeSlots = ['10:00', '14:00', '16:30'];
  static const defaultSlot = '10:00';
  static const daysOffered = 6;

  final ViewingRepository _repository;
  final Property property;

  static ContactOwnerState _initial(DateTime today) {
    final start = DateTime(today.year, today.month, today.day + 1);
    final dates = [
      for (var i = 0; i < daysOffered; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    return ContactOwnerState(dates: dates, selectedDate: dates.first);
  }

  void selectChannel(ContactChannel channel) =>
      emit(state.copyWith(channel: channel));

  void selectDate(DateTime date) => emit(state.copyWith(selectedDate: date));

  void selectSlot(String slot) => emit(state.copyWith(selectedSlot: slot));

  Future<void> submit(String message) async {
    if (state.status.isLoading) return;
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final created = await _repository.requestViewing(
        ViewingRequest(
          id: '',
          propertyId: property.id,
          propertyTitle: property.title,
          landlordId: property.owner.id,
          ownerName: property.owner.name,
          ownerReplyMinutes: property.owner.typicalReplyMinutes,
          scheduledAt: state.scheduledAt,
          channel: state.channel,
          message: message.trim(),
        ),
      );
      emit(state.copyWith(status: RequestStatus.success, created: created));
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          errorMessage:
              'We couldn\'t send your request. Check your '
              'connection and try again.',
        ),
      );
    }
  }
}
