/// Build-time settings, passed with `--dart-define-from-file=config/firebase.json`
/// (see `config/firebase.example.json`). Without them the app runs the demo.
abstract final class AppConfig {
  /// `demo` (default) or `firebase`.
  static const backend = String.fromEnvironment('AMOUR_BACKEND', defaultValue: 'demo');

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseDatabaseUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');
  static const firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const functionsRegion = String.fromEnvironment('FIREBASE_FUNCTIONS_REGION', defaultValue: 'us-central1');

  /// OAuth "Web client" id from the Firebase project (Google sign-in on Android).
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Point the app at the local Firebase emulators (10.0.2.2 = host machine
  /// from the Android emulator).
  static const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '10.0.2.2');

  static bool get firebaseEnabled =>
      backend == 'firebase' && firebaseApiKey.isNotEmpty && firebaseAppId.isNotEmpty && firebaseProjectId.isNotEmpty && firebaseDatabaseUrl.isNotEmpty;
}
