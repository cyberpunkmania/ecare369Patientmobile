import '../../domain/entities/auth_entity.dart';
import 'user_model.dart';

/// Data model for LoginResponseDto from the API.
class AuthModel extends AuthEntity {
  const AuthModel({
    required UserModel user,
    required super.accessToken,
    required super.refreshToken,
    required super.expiresAt,
  }) : super(user: user);

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // Handle nested data wrapper if present
    final data = json['data'] as Map<String, dynamic>? ?? json;

    // Parse user - might be nested under 'user' or at top level
    final userData = data['user'] as Map<String, dynamic>? ?? data;

    // Parse expiresAt
    DateTime expiresAt;
    final expiresAtRaw = data['expiresAt'];
    if (expiresAtRaw != null && expiresAtRaw is String) {
      expiresAt = DateTime.parse(expiresAtRaw);
    } else {
      // Default to 1 hour from now
      expiresAt = DateTime.now().add(const Duration(hours: 1));
    }

    return AuthModel(
      user: UserModel.fromJson(userData),
      accessToken:
          data['accessToken'] as String? ?? data['token'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': (user as UserModel).toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

/// Data model for TokenResponseDto (refresh token response).
class TokenRefreshModel extends TokenRefreshEntity {
  const TokenRefreshModel({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresAt,
  });

  factory TokenRefreshModel.fromJson(Map<String, dynamic> json) {
    // Handle nested data wrapper if present
    final data = json['data'] as Map<String, dynamic>? ?? json;

    // Parse expiresAt
    DateTime expiresAt;
    final expiresAtRaw = data['expiresAt'];
    if (expiresAtRaw != null && expiresAtRaw is String) {
      expiresAt = DateTime.parse(expiresAtRaw);
    } else {
      expiresAt = DateTime.now().add(const Duration(hours: 1));
    }

    return TokenRefreshModel(
      accessToken: data['accessToken'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
