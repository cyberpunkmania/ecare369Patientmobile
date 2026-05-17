import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/patient_registration_entity.dart';
import '../../domain/entities/security_question_entity.dart';
import '../models/auth_model.dart';
import '../models/lookup_result_model.dart';
import '../models/otp_response_model.dart';
import '../models/patient_registration_model.dart';
import '../models/security_question_model.dart';

/// Handles all auth-related API calls for the multi-flow authentication system.
///
/// Supports two registration paths:
/// - Path A (Full Self-Registration): Register with password → Lookup → Setup → Confirm
/// - Path B (Orphan Patient): Lookup (userId=null) → Setup (creates user) → Confirm
///
/// And three login flows:
/// - Flow A (Active): Email lookup → Password → OTP verification
/// - Flow B (Onboarding): Email lookup → Account setup → OTP confirmation
/// - Flow C (Inactive): Email lookup → Security Q&A → Password reset
abstract class AuthRemoteDataSource {
  // ══════════════════════════════════════════════════════════════════════════
  // ── Patient Registration ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Register a new patient (Path A: Full Self-Registration).
  /// Creates both Patient and User records when patientType = PatientUser.
  /// Returns PatientDto with the created patient information.
  Future<PatientModel> registerPatient({
    required PatientRegistrationRequest request,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Email Lookup (Common entry point for all flows) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Lookup user accounts by email address.
  /// Returns available accounts categorized by status (active, inactive, onboarding).
  /// For orphan patients, returns accounts with userId = null.
  Future<LookupResultModel> lookupEmail({required String email});

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow A: Active User Login ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Generate OTP after password verification for active user login.
  /// Request: { email, userId, password }
  Future<OtpResponseModel> generateLoginOtp({
    required String email,
    required String userId,
    required String password,
  });

  /// Verify OTP and complete login for active users.
  /// Request: { userId, otpCode }
  /// Returns auth tokens and user data on success.
  Future<AuthModel> verifyLoginOtp({
    required String userId,
    required String otpCode,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow B: New Account Onboarding ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch available security questions for new account setup.
  /// Returns a list of 3 randomly selected security question strings.
  Future<List<String>> getSecurityQuestions();

  /// Setup new account with password and security questions.
  ///
  /// For existing users (userId != null):
  ///   - Uses the existing user record
  ///
  /// For orphan patients (userId == null):
  ///   - Requires patientId and tenantId
  ///   - Creates a new User and links to Patient
  Future<OtpResponseModel> setupAccount({
    required String email,
    String? userId,
    required String password,
    required String confirmPassword,
    required List<SecurityQuestionAnswer> securityQuestions,
    String? patientId,
    String? tenantId,
  });

  /// Confirm onboarding with OTP verification.
  /// Request: { email, userId, otpCode, patientId? }
  /// Returns auth tokens and user data on success.
  Future<AuthModel> confirmOnboarding({
    required String email,
    required String userId,
    required String otpCode,
    String? patientId,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow C: Inactive Account Reactivation ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch user's security questions for account reactivation.
  Future<UserSecurityQuestionsModel> fetchUserSecurityQuestions({
    required String email,
    required String tenantId,
  });

  /// Reactivate inactive account with security answers and new password.
  /// Returns auth tokens and user data on success.
  Future<AuthModel> activateExistingUser({
    required String email,
    required String tenantId,
    required String newPassword,
    required List<SecurityQuestionAnswer> securityAnswers,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Token Management ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Refresh access token using refresh token.
  Future<TokenRefreshModel> refreshToken({required String refreshToken});

  /// Logout and invalidate tokens.
  Future<void> logout({String? refreshToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  // ══════════════════════════════════════════════════════════════════════════
  // ── Patient Registration ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<PatientModel> registerPatient({
    required PatientRegistrationRequest request,
  }) async {
    try {
      final requestModel = PatientRegistrationRequestModel.fromEntity(request);
      final response = await _dio.post(
        ApiEndpoints.patientRegister,
        data: requestModel.toJson(),
      );
      return PatientModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Email Lookup ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<LookupResultModel> lookupEmail({required String email}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authLookup,
        data: {'email': email},
      );
      return LookupResultModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow A: Active User Login ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<OtpResponseModel> generateLoginOtp({
    required String email,
    required String userId,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authGenerateLoginOtp,
        data: {'email': email, 'userId': userId, 'password': password},
      );
      return OtpResponseModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  @override
  Future<AuthModel> verifyLoginOtp({
    required String userId,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authVerifyLoginOtp,
        data: {'userId': userId, 'otpCode': otpCode},
      );
      return AuthModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow B: New Account Onboarding ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<String>> getSecurityQuestions() async {
    try {
      final response = await _dio.get(ApiEndpoints.authSecurityQuestions);
      final data = response.data as Map<String, dynamic>;

      // API returns: { message: string, data: string[] }
      final questionsData = data['data'] as List<dynamic>? ?? [];

      return questionsData.map((q) => q.toString()).toList();
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  @override
  Future<OtpResponseModel> setupAccount({
    required String email,
    String? userId,
    required String password,
    required String confirmPassword,
    required List<SecurityQuestionAnswer> securityQuestions,
    String? patientId,
    String? tenantId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authSetupAccount,
        data: {
          'email': email,
          'userId': userId,
          'password': password,
          'confirmPassword': confirmPassword,
          'securityQuestions': securityQuestions
              .map((sq) => {'question': sq.question ?? '', 'answer': sq.answer})
              .toList(),
          // Required for orphan patients (userId == null)
          if (patientId != null) 'patientId': patientId,
          if (tenantId != null) 'tenantId': tenantId,
        },
      );
      return OtpResponseModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  @override
  Future<AuthModel> confirmOnboarding({
    required String email,
    required String userId,
    required String otpCode,
    String? patientId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authConfirmOnboarding,
        data: {
          'email': email,
          'userId': userId,
          'otpCode': otpCode,
          if (patientId != null) 'patientId': patientId,
        },
      );
      return AuthModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow C: Inactive Account Reactivation ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<UserSecurityQuestionsModel> fetchUserSecurityQuestions({
    required String email,
    required String tenantId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authFetchSecurityQuestions,
        data: {'email': email, 'tenantId': tenantId},
      );
      return UserSecurityQuestionsModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  @override
  Future<AuthModel> activateExistingUser({
    required String email,
    required String tenantId,
    required String newPassword,
    required List<SecurityQuestionAnswer> securityAnswers,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authActivateExistingUser,
        data: {
          'email': email,
          'tenantId': tenantId,
          'newPassword': newPassword,
          'securityAnswers': securityAnswers
              .map(
                (sq) => SecurityQuestionAnswerModel(
                  questionId: sq.questionId,
                  answer: sq.answer,
                ).toReactivationJson(),
              )
              .toList(),
        },
      );
      return AuthModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Token Management ──
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Future<TokenRefreshModel> refreshToken({required String refreshToken}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      return TokenRefreshModel.fromJson(
        _unwrapData(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _extractServerException(e);
    }
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    try {
      await _dio.post(
        ApiEndpoints.authLogout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : null,
      );
    } on DioException catch (_) {
      // Logout should succeed locally even if server call fails.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Error Handling ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Unwraps the API envelope: { message, data: { ... }, timestamp }
  /// If the response contains a 'data' key with a Map value, returns that inner map.
  /// Otherwise returns the response map as-is for backward compatibility.
  Map<String, dynamic> _unwrapData(Map<String, dynamic> responseData) {
    if (responseData.containsKey('data') && responseData['data'] is Map) {
      return responseData['data'] as Map<String, dynamic>;
    }
    return responseData;
  }

  ServerException _extractServerException(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;

    // Try to extract error message from response body
    String message = e.message ?? 'Unknown server error';
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      message =
          data['message'] as String? ?? data['error'] as String? ?? message;
    }

    return ServerException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}
