/// Environment configuration for the E-Care Patient app.
///
/// The base URL is resolved with the following precedence:
/// 1. `--dart-define=API_BASE_URL=...` (build-time override)
/// 2. A sensible default per platform pointing at the local Identity API on
///    port `5216` so that emulator / simulator / desktop builds "just work".
class EnvConfig {
  EnvConfig._();

  static const String _localUrl = 'http://localhost:5216';
  static const String _productionUrl = 'https://ecarehmis.onrender.com';

  /// Toggle: set to [true] to hit local backend, [false] for the deployed server.
  static const bool _useLocal = true;

  static String get baseUrl => _useLocal ? _localUrl : _productionUrl;

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
