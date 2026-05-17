import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// Wraps user + tokens returned after successful login (all flows converge here).
/// Matches LoginResponseDto from the backend.
class AuthEntity extends Equatable {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthEntity({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// For backwards compatibility.
  String get token => accessToken;

  /// For backwards compatibility.
  String? get tokenExpiry => expiresAt.toIso8601String();

  /// Whether the access token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the token is about to expire (within 5 minutes).
  bool get isAboutToExpire {
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return expiresAt.isBefore(fiveMinutesFromNow);
  }

  @override
  List<Object?> get props => [user, accessToken, refreshToken, expiresAt];
}

/// Response from token refresh endpoint.
class TokenRefreshEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const TokenRefreshEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}
