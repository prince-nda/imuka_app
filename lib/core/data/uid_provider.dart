/// Returns the signed-in user's id. Repositories for per-user data call it
/// on every request, so they always read and write the current user's
/// documents (and nothing else, as the security rules also enforce).
typedef UidProvider = String Function();

/// Thrown when per-user data is requested while signed out.
class NotSignedInException implements Exception {
  const NotSignedInException();

  @override
  String toString() => 'NotSignedInException: please log in again.';
}
