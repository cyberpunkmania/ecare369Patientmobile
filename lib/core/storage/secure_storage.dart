import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [FlutterSecureStorage] for auth tokens and patient context.
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  // ── Keys ──
  static const _authTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  static const _userIdKey = 'user_id';
  static const _patientIdKey = 'patient_id';
  static const _tenantIdKey = 'tenant_id';

  // ── Auth Token ──
  Future<void> saveAuthToken(String token) =>
      _storage.write(key: _authTokenKey, value: token);

  Future<String?> getAuthToken() => _storage.read(key: _authTokenKey);

  Future<void> deleteAuthToken() => _storage.delete(key: _authTokenKey);

  // ── Refresh Token ──
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  // ── Token Expiry ──
  Future<void> saveTokenExpiry(String expiry) =>
      _storage.write(key: _tokenExpiryKey, value: expiry);

  Future<String?> getTokenExpiry() => _storage.read(key: _tokenExpiryKey);

  // ── User ID ──
  Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  // ── Patient ID ──
  Future<void> savePatientId(String patientId) =>
      _storage.write(key: _patientIdKey, value: patientId);

  Future<String?> getPatientId() => _storage.read(key: _patientIdKey);

  // ── Tenant ID ──
  Future<void> saveTenantId(String tenantId) =>
      _storage.write(key: _tenantIdKey, value: tenantId);

  Future<String?> getTenantId() => _storage.read(key: _tenantIdKey);

  // ── Clear All ──
  Future<void> clearAll() => _storage.deleteAll();

  /// Returns `true` if an auth token is present.
  Future<bool> hasToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
