import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Caches auth data locally using [SecureStorage].
///
/// Stores:
/// - Access and refresh tokens
/// - Token expiration time
/// - User profile data
/// - Selected tenant/branch context
abstract class AuthLocalDataSource {
  /// Cache complete auth response including tokens and user data.
  Future<void> cacheAuth({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required UserModel user,
  });

  /// Cache only tokens (for refresh token response).
  Future<void> cacheTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  });

  /// Cache the selected tenant and branch for the current session.
  Future<void> cacheAccountContext({
    required String tenantId,
    required String branchId,
  });

  /// Get the cached account context (tenantId, branchId).
  Future<Map<String, String>?> getAccountContext();

  /// Get the cached user data.
  Future<UserModel> getLastUser();

  /// Get the cached access token.
  Future<String?> getAccessToken();

  /// Get the cached refresh token.
  Future<String?> getRefreshToken();

  /// Get the token expiration time.
  Future<DateTime?> getTokenExpiry();

  /// Check if the cached token is expired or about to expire.
  Future<bool> isTokenExpired({Duration buffer = const Duration(minutes: 5)});

  /// Clear all cached auth data.
  Future<void> clearAuth();

  /// Check if there is a valid cached token.
  Future<bool> hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage _secureStorage;
  final FlutterSecureStorage _rawStorage;

  static const _userKey = 'cached_user';
  static const _tenantIdKey = 'selected_tenant_id';
  static const _branchIdKey = 'selected_branch_id';
  static const _tokenExpiryKey = 'token_expiry_iso';

  AuthLocalDataSourceImpl({
    required SecureStorage secureStorage,
    FlutterSecureStorage? rawStorage,
  }) : _secureStorage = secureStorage,
       _rawStorage = rawStorage ?? const FlutterSecureStorage();

  @override
  Future<void> cacheAuth({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required UserModel user,
  }) async {
    // Store tokens
    await _secureStorage.saveAuthToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);
    await _rawStorage.write(
      key: _tokenExpiryKey,
      value: expiresAt.toIso8601String(),
    );

    // Store user identifiers for quick access
    await _secureStorage.saveUserId(user.id);
    if (user.patientId != null) {
      await _secureStorage.savePatientId(user.patientId!);
    }
    if (user.tenantId != null) {
      await _secureStorage.saveTenantId(user.tenantId!);
    }

    // Store full user JSON for offline access
    final userJson = json.encode(user.toJson());
    await _rawStorage.write(key: _userKey, value: userJson);
  }

  @override
  Future<void> cacheTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    await _secureStorage.saveAuthToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);
    await _rawStorage.write(
      key: _tokenExpiryKey,
      value: expiresAt.toIso8601String(),
    );
  }

  @override
  Future<void> cacheAccountContext({
    required String tenantId,
    required String branchId,
  }) async {
    await _rawStorage.write(key: _tenantIdKey, value: tenantId);
    await _rawStorage.write(key: _branchIdKey, value: branchId);
    // Also write to the key that auth_interceptor reads ('tenant_id' via SecureStorage).
    await _secureStorage.saveTenantId(tenantId);
  }

  @override
  Future<Map<String, String>?> getAccountContext() async {
    final tenantId = await _rawStorage.read(key: _tenantIdKey);
    final branchId = await _rawStorage.read(key: _branchIdKey);

    if (tenantId == null || branchId == null) {
      return null;
    }

    return {'tenantId': tenantId, 'branchId': branchId};
  }

  @override
  Future<UserModel> getLastUser() async {
    final raw = await _rawStorage.read(key: _userKey);
    if (raw == null || raw.isEmpty) {
      throw const CacheException(message: 'No cached user found');
    }
    return UserModel.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  @override
  Future<String?> getAccessToken() async {
    return _secureStorage.getAuthToken();
  }

  @override
  Future<String?> getRefreshToken() async {
    return _secureStorage.getRefreshToken();
  }

  @override
  Future<DateTime?> getTokenExpiry() async {
    final expiryStr = await _rawStorage.read(key: _tokenExpiryKey);
    if (expiryStr == null || expiryStr.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(expiryStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isTokenExpired({
    Duration buffer = const Duration(minutes: 5),
  }) async {
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      return true; // No expiry info, assume expired
    }
    return DateTime.now().add(buffer).isAfter(expiry);
  }

  @override
  Future<void> clearAuth() async {
    await _secureStorage.clearAll();
    await _rawStorage.delete(key: _userKey);
    await _rawStorage.delete(key: _tenantIdKey);
    await _rawStorage.delete(key: _branchIdKey);
    await _rawStorage.delete(key: _tokenExpiryKey);
  }

  @override
  Future<bool> hasToken() => _secureStorage.hasToken();
}
