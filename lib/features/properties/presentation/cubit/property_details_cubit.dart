import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';

typedef PropertyDetailsState = ({RequestStatus status, Property? property});

/// Loads a single listing for the details screen.
class PropertyDetailsCubit extends Cubit<PropertyDetailsState>
    with SafeEmit<PropertyDetailsState> {
  PropertyDetailsCubit(this._repository, {Property? initial})
    : super((
        status: initial == null ? RequestStatus.initial : RequestStatus.success,
        property: initial,
      ));

  final PropertyRepository _repository;

  Future<void> load(String id) async {
    if (state.property?.id == id) return;
    emit((status: RequestStatus.loading, property: null));
    try {
      final property = await _repository.getProperty(id);
      emit((
        status: property == null
            ? RequestStatus.failure
            : RequestStatus.success,
        property: property,
      ));
    } catch (_) {
      emit((status: RequestStatus.failure, property: null));
    }
  }
}
