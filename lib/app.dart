import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/move/domain/repositories/move_repositories.dart';
import 'features/move/presentation/cubit/move_booking_cubit.dart';
import 'features/move/presentation/cubit/move_plan_cubit.dart';
import 'features/move/presentation/cubit/move_tasks_cubit.dart';
import 'features/properties/domain/repositories/property_repository.dart';
import 'features/properties/presentation/cubit/property_search_cubit.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/shortlist/domain/repositories/shortlist_repository.dart';
import 'features/shortlist/presentation/cubit/shortlist_cubit.dart';
import 'features/viewing/domain/repositories/viewing_repository.dart';

/// Every repository the app depends on. Swapping the mock implementations
/// for Firebase ones happens in `main.dart` only.
class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.settings,
    required this.properties,
    required this.shortlist,
    required this.viewings,
    required this.movePlans,
    required this.moveItems,
    required this.moveTasks,
    required this.movers,
  });

  final AuthRepository auth;
  final SettingsRepository settings;
  final PropertyRepository properties;
  final ShortlistRepository shortlist;
  final ViewingRepository viewings;
  final MovePlanRepository movePlans;
  final MoveItemRepository moveItems;
  final MoveTaskRepository moveTasks;
  final MoverRepository movers;
}

/// Provides repositories and app-wide Cubits, then builds the router.
class ImukaApp extends StatelessWidget {
  const ImukaApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final d = dependencies;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: d.auth),
        RepositoryProvider.value(value: d.settings),
        RepositoryProvider.value(value: d.properties),
        RepositoryProvider.value(value: d.shortlist),
        RepositoryProvider.value(value: d.viewings),
        RepositoryProvider.value(value: d.movePlans),
        RepositoryProvider.value(value: d.moveItems),
        RepositoryProvider.value(value: d.moveTasks),
        RepositoryProvider.value(value: d.movers),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(d.auth)),
          BlocProvider(create: (_) => SettingsCubit(d.settings)),
          BlocProvider(
            create: (context) => PropertySearchCubit(
              d.properties,
              verifiedOnly: context
                  .read<SettingsCubit>()
                  .state
                  .verifiedOnlyByDefault,
            ),
          ),
          BlocProvider(create: (_) => ShortlistCubit(d.shortlist)),
          BlocProvider(
            create: (_) =>
                MovePlanCubit(d.moveItems, planRepository: d.movePlans),
          ),
          BlocProvider(create: (_) => MoveTasksCubit(d.moveTasks)),
          BlocProvider(
            create: (context) => MoveBookingCubit(
              d.movers,
              paymentMethod: context
                  .read<SettingsCubit>()
                  .state
                  .preferredPayment,
            ),
          ),
        ],
        child: const _SessionData(child: _RouterApp()),
      ),
    );
  }
}

/// Loads the signed-in user's data when a session starts and clears it on
/// logout, so one user's move never shows up for another.
class _SessionData extends StatefulWidget {
  const _SessionData({required this.child});

  final Widget child;

  @override
  State<_SessionData> createState() => _SessionDataState();
}

/// Stateful only to trigger the first load for a restored session.
class _SessionDataState extends State<_SessionData> {
  @override
  void initState() {
    super.initState();
    if (_readyUserId(context.read<AuthCubit>().state) != null) _load(context);
  }

  /// The user id once the account is verified (email confirmed, or a
  /// Google account), otherwise `null`. The security rules only allow data access
  /// for verified accounts.
  static String? _readyUserId(AuthState state) {
    final user = state.user;
    if (user == null || user.needsEmailVerification) return null;
    return user.id;
  }

  static void _load(BuildContext context) {
    context.read<PropertySearchCubit>().load();
    context.read<ShortlistCubit>().load();
    context.read<MovePlanCubit>().load();
    context.read<MoveTasksCubit>().load();
    context.read<MoveBookingCubit>().restore();
  }

  static void _clear(BuildContext context) {
    context.read<ShortlistCubit>().reset();
    context.read<MovePlanCubit>().reset();
    context.read<MoveTasksCubit>().reset();
    context.read<MoveBookingCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      // React when a verified user becomes ready or the session ends, not
      // on profile updates such as a name change.
      listenWhen: (a, b) => _readyUserId(a) != _readyUserId(b),
      listener: (context, state) =>
          _readyUserId(state) == null ? _clear(context) : _load(context),
      child: widget.child,
    );
  }
}

class _RouterApp extends StatefulWidget {
  const _RouterApp();

  @override
  State<_RouterApp> createState() => _RouterAppState();
}

/// Stateful only so the router is created once and survives theme changes.
class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router = createRouter(context.read<AuthCubit>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, AppSettings, ThemeMode>(
      selector: (s) => s.themeMode,
      builder: (context, themeMode) => MaterialApp.router(
        title: 'Imuka',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: _router,
      ),
    );
  }
}
