import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/data/uid_provider.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/mock_auth_repository.dart';
import 'features/move/data/repositories/firestore_move_repositories.dart';
import 'features/move/data/repositories/mock_move_repositories.dart';
import 'features/properties/data/repositories/firestore_property_repository.dart';
import 'features/properties/data/repositories/mock_property_repository.dart';
import 'features/settings/data/repositories/shared_prefs_settings_repository.dart';
import 'features/shortlist/data/repositories/firestore_shortlist_repository.dart';
import 'features/shortlist/data/repositories/mock_shortlist_repository.dart';
import 'features/viewing/data/repositories/firestore_viewing_repository.dart';
import 'features/viewing/data/repositories/mock_viewing_repository.dart';
import 'firebase_options.dart';

/// Run with `--dart-define=USE_MOCKS=true` to use in-memory data (no
/// Firebase), e.g. for offline UI work.
const _useMocks = bool.fromEnvironment('USE_MOCKS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  final prefs = await SharedPreferences.getInstance();
  final settings = SharedPrefsSettingsRepository(prefs);

  final dependencies = _useMocks
      ? _mockDependencies(settings)
      : await _firebaseDependencies(settings);
  runApp(ImukaApp(dependencies: dependencies));
}

Future<AppDependencies> _firebaseDependencies(
  SharedPrefsSettingsRepository settings,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final auth = FirebaseAuthRepository();
  // Restore the saved session before the first frame, so a signed-in user
  // goes straight to Home instead of flashing the welcome screen.
  await auth.ready.timeout(const Duration(seconds: 5), onTimeout: () {});

  String uid() =>
      FirebaseAuth.instance.currentUser?.uid ??
      (throw const NotSignedInException());

  final properties = FirestorePropertyRepository();
  return AppDependencies(
    auth: auth,
    settings: settings,
    properties: properties,
    shortlist: FirestoreShortlistRepository(uid),
    viewings: FirestoreViewingRepository(uid, properties),
    movePlans: FirestoreMovePlanRepository(uid),
    moveItems: FirestoreMoveItemRepository(uid),
    moveTasks: FirestoreMoveTaskRepository(uid),
    movers: FirestoreMoverRepository(uid),
  );
}

AppDependencies _mockDependencies(SharedPrefsSettingsRepository settings) =>
    AppDependencies(
      auth: MockAuthRepository(),
      settings: settings,
      properties: MockPropertyRepository(),
      shortlist: MockShortlistRepository(),
      viewings: MockViewingRepository(),
      movePlans: MockMovePlanRepository(),
      moveItems: MockMoveItemRepository(),
      moveTasks: MockMoveTaskRepository(),
      movers: MockMoverRepository(),
    );
