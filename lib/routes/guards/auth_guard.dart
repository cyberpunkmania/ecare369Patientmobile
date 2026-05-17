import 'package:flutter/material.dart';

import '../../core/storage/secure_storage.dart';
import '../app_router.dart';

/// Navigation guard that redirects unauthenticated users to auth page.
///
/// Usage in widgets:
/// ```dart
/// final guard = GetIt.I<AuthGuard>();
/// guard.navigate(context, Routes.appointments);
/// ```
class AuthGuard {
  final SecureStorage _secureStorage;

  AuthGuard({required SecureStorage secureStorage})
    : _secureStorage = secureStorage;

  /// Returns `true` when the user has a stored auth token.
  Future<bool> get isAuthenticated => _secureStorage.hasToken();

  /// Push a named route only if authenticated; otherwise redirect to auth.
  Future<void> navigate(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (await isAuthenticated) {
      if (context.mounted) {
        Navigator.pushNamed(context, routeName, arguments: arguments);
      }
    } else {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.auth, (_) => false);
      }
    }
  }

  /// Determines the initial route based on auth state.
  Future<String> get initialRoute async {
    final loggedIn = await isAuthenticated;
    return loggedIn ? Routes.dashboard : Routes.auth;
  }
}
