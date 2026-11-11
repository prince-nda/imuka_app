import 'package:flutter_bloc/flutter_bloc.dart';

/// For Cubits owned by a screen: network results that arrive after the user
/// left the screen are ignored instead of throwing "Cannot emit new states
/// after calling close".
mixin SafeEmit<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (!isClosed) super.emit(state);
  }
}
