import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/move/presentation/pages/check_items_page.dart';
import '../../features/move/presentation/pages/choose_movers_page.dart';
import '../../features/move/presentation/pages/live_tracking_page.dart';
import '../../features/move/presentation/pages/move_complete_page.dart';
import '../../features/move/presentation/pages/move_items_page.dart';
import '../../features/move/presentation/pages/move_tasks_page.dart';
import '../../features/move/presentation/pages/moving_costs_page.dart';
import '../../features/move/presentation/pages/my_move_page.dart';
import '../../features/move/presentation/pages/payment_page.dart';
import '../../features/properties/presentation/pages/find_home_page.dart';
import '../../features/properties/presentation/pages/home_page.dart';
import '../../features/properties/presentation/pages/how_we_verify_page.dart';
import '../../features/properties/presentation/pages/property_details_page.dart';
import '../../features/properties/presentation/pages/search_results_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shortlist/presentation/pages/compare_page.dart';
import '../../features/viewing/domain/entities/viewing_request.dart';
import '../../features/viewing/presentation/pages/contact_owner_page.dart';
import '../../features/viewing/presentation/pages/my_viewings_page.dart';
import '../../features/viewing/presentation/pages/viewing_requested_page.dart';
import 'app_routes.dart';
import 'main_shell.dart';
import 'stream_listenable.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds the app router.
///
/// * Signed-out users can only reach the authentication screens.
/// * Email accounts must verify their email address before using the app.
/// * The four tabs live in a [StatefulShellRoute], so each tab keeps its own
///   scroll position and back stack.
/// * Detail screens are pushed on the root navigator, hiding the bottom
///   navigation as in the Figma prototype.
GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: StreamListenable(authCubit.stream),
    redirect: (context, state) =>
        authRedirect(authCubit.state, state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupPage()),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, _) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, _) => const VerifyEmailPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (_, _) => const FindHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.move,
                builder: (_, _) => const MyMovePage(),
                routes: [
                  _fullScreen('items', const MoveItemsPage()),
                  _fullScreen('costs', const MovingCostsPage()),
                  _fullScreen('movers', const ChooseMoversPage()),
                  _fullScreen('tracking', const LiveTrackingPage()),
                  _fullScreen('check', const CheckItemsPage()),
                  _fullScreen('payment', const PaymentPage()),
                  _fullScreen('complete', const MoveCompletePage()),
                  _fullScreen('tasks', const MoveTasksPage()),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shortlist,
                builder: (_, _) => const ComparePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (_, _) => const SearchResultsPage(),
      ),
      GoRoute(
        path: '/property/:id',
        builder: (_, state) =>
            PropertyDetailsPage(propertyId: state.pathParameters['id']!),
        routes: [
          GoRoute(path: 'verify', builder: (_, _) => const HowWeVerifyPage()),
          GoRoute(
            path: 'contact',
            builder: (_, state) =>
                ContactOwnerPage(propertyId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.viewingRequested,
        redirect: (_, state) =>
            state.extra is ViewingRequest ? null : AppRoutes.home,
        builder: (_, state) =>
            ViewingRequestedPage(request: state.extra! as ViewingRequest),
      ),
      GoRoute(
        path: AppRoutes.myViewings,
        builder: (_, _) => const MyViewingsPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
  );
}

/// A My Move sub-screen shown above the bottom navigation.
GoRoute _fullScreen(String path, Widget page) =>
    GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (_, _) => page);

/// Where to send the user for the current auth state, or `null` to stay.
/// Public so the rules can be unit-tested.
String? authRedirect(AuthState auth, String location) {
  final onAuthRoute = AppRoutes.authRoutes.contains(location);
  final user = auth.user;

  if (user == null) return onAuthRoute ? null : AppRoutes.welcome;
  if (user.needsEmailVerification) {
    return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }
  if (onAuthRoute || location == AppRoutes.verifyEmail) return AppRoutes.home;
  return null;
}
