import 'package:equatable/equatable.dart';

/// Base class for all failures returned via [Either].
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// A failure originating from the remote server / API.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// A failure originating from the local cache.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// A failure caused by lack of network connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

/// A failure related to authentication (expired session, invalid credentials, etc.).
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}
