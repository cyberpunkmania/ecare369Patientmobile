/// Environment configuration for the E-Care Patient app.
///
/// The base URL is resolved with the following precedence:
/// 1. `--dart-define=API_BASE_URL=...` (build-time override)
/// 2. A sensible default per platform pointing at the local Identity API on
///    port `5216` so that emulator / simulator / desktop builds "just work".
class EnvConfig {
  EnvConfig._();

  /// Optional build-time override:
  /// `flutter run --dart-define=API_BASE_URL=https://staging.example.com`
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Production backend URL (Render deployment).
  static const String _productionUrl = 'https://ecarehmis.onrender.com';

  /// Returns the production URL by default.
  /// Pass `--dart-define=API_BASE_URL=http://10.0.2.2:5216` to point at a
  /// local backend during development.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return _productionUrl;
  }

  /// SignalR notification hub absolute URL. Lives on the **Notifications**
  /// service (separate port in some deployments — falls back to the same host
  /// when not overridden).
  static const String _hubOverride = String.fromEnvironment('HUB_URL');
  static String get notificationHubUrl {
    if (_hubOverride.isNotEmpty) return _hubOverride;
    return '$baseUrl/notificationhub';
  }

  /// Request timeout in milliseconds.
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
}
