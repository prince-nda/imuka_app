/// Every route path in the app, in one place.
abstract final class AppRoutes {
  // Authentication (reachable only when signed out).
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const resetPassword = '/reset-password';

  static const authRoutes = {welcome, login, signup, resetPassword};

  // Account setup (signed in, before the main app).
  static const verifyEmail = '/verify-email';

  // Bottom navigation tabs.
  static const home = '/home';
  static const search = '/search';
  static const move = '/move';
  static const shortlist = '/shortlist';

  // My Move flow (full screen, pushed above the tabs).
  static const moveItems = '/move/items';
  static const moveCosts = '/move/costs';
  static const movers = '/move/movers';
  static const tracking = '/move/tracking';
  static const checkItems = '/move/check';
  static const payment = '/move/payment';
  static const moveComplete = '/move/complete';
  static const moveTasks = '/move/tasks';

  // Housing screens.
  static const searchResults = '/results';
  static const viewingRequested = '/viewing-requested';
  static const settings = '/settings';
  static const myViewings = '/viewings';

  static String property(String id) => '/property/$id';
  static String howWeVerify(String id) => '/property/$id/verify';
  static String contactOwner(String id) => '/property/$id/contact';
}
