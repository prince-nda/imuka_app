import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../domain/entities/move_plan.dart';
import '../../domain/entities/mover.dart';
import '../../domain/entities/tracking_update.dart';
import '../../domain/repositories/move_repositories.dart';

/// Streams the truck position while the tracking screen is open.
class TrackingCubit extends Cubit<TrackingUpdate?>
    with SafeEmit<TrackingUpdate?> {
  TrackingCubit(this._repository) : super(null);

  final MoverRepository _repository;
  StreamSubscription<TrackingUpdate>? _subscription;

  void start({required Mover mover, required MovePlan plan}) {
    _subscription?.cancel();
    _subscription = _repository
        .trackMove(mover: mover, plan: plan)
        .listen(emit);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
