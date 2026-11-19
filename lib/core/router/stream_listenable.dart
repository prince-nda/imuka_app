import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a stream (e.g. a Cubit's state stream) into a [Listenable] so
/// GoRouter re-runs its redirect whenever the auth state changes.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
