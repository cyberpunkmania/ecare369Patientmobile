import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/entities/lookup_result_entity.dart';
import '../../domain/entities/otp_response_entity.dart';
import '../../domain/entities/patient_registration_entity.dart';
import '../../domain/entities/security_question_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository] supporting multi-flow authentication.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;

  // ══════════════════════════════════════════════════════════════════════════
  // ── Patient Registration ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, PatientEntity>> registerPatient({
    required PatientRegistrationRequest request,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remoteDataSource.registerPatient(request: request);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Email Lookup ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, LookupResultEntity>> lookupEmail({
    required String email,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remoteDataSource.lookupEmail(email: email);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow A: Active User Login ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, OtpResponseEntity>> generateLoginOtp({
    required String email,
    required String userId,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remoteDataSource.generateLoginOtp(
        email: email,
        userId: userId,
        password: password,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> verifyLoginOtp({
    required String userId,
    required String otpCode,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final authModel = await _remoteDataSource.verifyLoginOtp(
        userId: userId,
        otpCode: otpCode,
      );
      await _cacheAuthData(authModel);
      return Right(authModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow B: New Account Onboarding ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<String>>> getSecurityQuestions() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final questions = await _remoteDataSource.getSecurityQuestions();
      return Right(questions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, OtpResponseEntity>> setupAccount({
    required String email,
    String? userId,
    required String password,
    required String confirmPassword,
    required List<SecurityQuestionAnswer> securityQuestions,
    String? patientId,
    String? tenantId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remoteDataSource.setupAccount(
        email: email,
        userId: userId,
        password: password,
        confirmPassword: confirmPassword,
        securityQuestions: securityQuestions,
        patientId: patientId,
        tenantId: tenantId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> confirmOnboarding({
    required String email,
    required String userId,
    required String otpCode,
    String? patientId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final authModel = await _remoteDataSource.confirmOnboarding(
        email: email,
        userId: userId,
        otpCode: otpCode,
        patientId: patientId,
      );
      await _cacheAuthData(authModel);
      return Right(authModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow C: Inactive Account Reactivation ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, UserSecurityQuestionsEntity>>
  fetchUserSecurityQuestions({
    required String email,
    required String tenantId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remoteDataSource.fetchUserSecurityQuestions(
        email: email,
        tenantId: tenantId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> activateExistingUser({
    required String email,
    required String tenantId,
    required String newPassword,
    required List<SecurityQuestionAnswer> securityAnswers,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final authModel = await _remoteDataSource.activateExistingUser(
        email: email,
        tenantId: tenantId,
        newPassword: newPassword,
        securityAnswers: securityAnswers,
      );
      await _cacheAuthData(authModel);
      return Right(authModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Token Management ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, TokenRefreshEntity>> refreshToken() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final storedRefreshToken = await _localDataSource.getRefreshToken();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        return const Left(AuthFailure(message: 'No refresh token available'));
      }

      final tokenResponse = await _remoteDataSource.refreshToken(
        refreshToken: storedRefreshToken,
      );

      // Cache the new tokens
      await _localDataSource.cacheTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        expiresAt: tokenResponse.expiresAt,
      );

      return Right(tokenResponse);
    } on ServerException catch (e) {
      // If refresh fails, clear auth data (session expired)
      if (e.statusCode == 401) {
        await _localDataSource.clearAuth();
        return const Left(
          AuthFailure(message: 'Session expired. Please login again.'),
        );
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Session Management ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await _localDataSource.getLastUser();
      return Right(user);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      await _remoteDataSource.logout(refreshToken: refreshToken);
      await _localDataSource.clearAuth();
      return const Right(null);
    } catch (e) {
      // Force local clear even on error
      await _localDataSource.clearAuth();
      return const Right(null);
    }
  }

  @override
  Future<bool> isLoggedIn() => _localDataSource.hasToken();

  @override
  Future<bool> isTokenExpired() => _localDataSource.isTokenExpired();

  @override
  Future<Either<Failure, Map<String, String>>> getAccountContext() async {
    try {
      final context = await _localDataSource.getAccountContext();
      if (context == null) {
        return const Left(CacheFailure(message: 'No account context found'));
      }
      return Right(context);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<void> saveAccountContext({
    required String tenantId,
    String? branchId,
  }) async {
    await _localDataSource.cacheAccountContext(
      tenantId: tenantId,
      branchId: branchId ?? '',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Private Helpers ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Cache all auth data from a successful login response.
  Future<void> _cacheAuthData(AuthEntity auth) async {
    await _localDataSource.cacheAuth(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      expiresAt: auth.expiresAt,
      user: auth.user as UserModel,
    );
  }
}
