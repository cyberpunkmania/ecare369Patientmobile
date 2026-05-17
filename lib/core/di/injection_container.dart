import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache/cache_manager.dart';
import '../cache/memory_cache.dart';
import '../cache/persistent_cache.dart';
import '../connectivity/connectivity_bloc.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/error_interceptor.dart';
import '../network/network_info.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../sync/sync_manager.dart';
import '../theme/theme_cubit.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/appointments/data/datasources/appointment_local_datasource.dart';
import '../../features/appointments/data/datasources/appointment_remote_datasource.dart';
import '../../features/appointments/data/datasources/booking_remote_datasource.dart';
import '../../features/appointments/data/repositories/appointment_repository_impl.dart';
import '../../features/appointments/data/repositories/booking_repository_impl.dart';
import '../../features/appointments/domain/repositories/appointment_repository.dart';
import '../../features/appointments/domain/repositories/booking_repository.dart';
import '../../features/appointments/domain/usecases/book_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/get_appointments_usecase.dart';
import '../../features/appointments/presentation/bloc/appointment_bloc.dart';
import '../../features/appointments/presentation/bloc/booking_cubit.dart';

import '../../features/medical_records/data/datasources/medical_record_local_datasource.dart';
import '../../features/medical_records/data/datasources/medical_record_remote_datasource.dart';
import '../../features/medical_records/data/repositories/medical_record_repository_impl.dart';
import '../../features/medical_records/domain/repositories/medical_record_repository.dart';
import '../../features/medical_records/domain/usecases/get_medical_records_usecase.dart';
import '../../features/medical_records/presentation/bloc/medical_record_bloc.dart';

import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/get_conversations_usecase.dart';
import '../../features/chat/domain/usecases/get_messages_usecase.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';

import '../../features/notifications/data/datasources/notification_local_datasource.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';

import '../../features/tenants/data/datasources/tenant_remote_datasource.dart';
import '../../features/tenants/data/repositories/tenant_repository_impl.dart';
import '../../features/tenants/domain/repositories/tenant_repository.dart';
import '../../features/tenants/domain/usecases/get_public_tenants_usecase.dart';
import '../../features/tenants/presentation/bloc/tenant_cubit.dart';

import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';

import '../../features/queue/data/datasources/queue_remote_datasource.dart';
import '../../features/queue/data/repositories/queue_repository_impl.dart';
import '../../features/queue/domain/repositories/queue_repository.dart';
import '../../features/queue/presentation/bloc/queue_cubit.dart';

import '../../features/dispensations/data/datasources/dispensation_remote_datasource.dart';
import '../../features/dispensations/data/repositories/dispensation_repository_impl.dart';
import '../../features/dispensations/domain/repositories/dispensation_repository.dart';
import '../../features/dispensations/presentation/bloc/dispensation_cubit.dart';

import '../../features/bills/data/datasources/bill_remote_datasource.dart';
import '../../features/bills/data/repositories/bill_repository_impl.dart';
import '../../features/bills/domain/repositories/bill_repository.dart';
import '../../features/bills/presentation/bloc/bills_cubit.dart';

import '../realtime/signalr_service.dart';

import '../../routes/guards/auth_guard.dart';

final sl = GetIt.instance;

/// Must be called before [runApp]. Registers all dependencies.
Future<void> initDependencies() async {
  // ─── External ─────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.createInstance(),
  );

  // ─── Core: Storage ────────────────────────────────────────
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorage(storage: sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<LocalStorage>(
    () => LocalStorage(prefs: sl<SharedPreferences>()),
  );

  // ─── Core: Network ────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(
      connectivity: sl<Connectivity>(),
      connectionChecker: sl<InternetConnectionChecker>(),
    ),
  );
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(secureStorage: sl<SecureStorage>()),
  );
  sl.registerLazySingleton<ErrorInterceptor>(() => ErrorInterceptor());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      authInterceptor: sl<AuthInterceptor>(),
      errorInterceptor: sl<ErrorInterceptor>(),
    ),
  );
  sl.registerLazySingleton<Dio>(() => sl<ApiClient>().dio);

  // ─── Core: Cache ──────────────────────────────────────────
  sl.registerLazySingleton<MemoryCache>(() => MemoryCache());
  sl.registerLazySingleton<PersistentCache>(() => PersistentCache());
  sl.registerLazySingleton<CacheManager>(
    () => CacheManager(
      memoryCache: sl<MemoryCache>(),
      persistentCache: sl<PersistentCache>(),
    ),
  );

  // ─── Core: Connectivity / Sync / Theme ────────────────────
  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(networkInfo: sl<NetworkInfo>(), dio: sl<Dio>()),
  );
  sl.registerFactory<ConnectivityBloc>(
    () => ConnectivityBloc(networkInfo: sl<NetworkInfo>()),
  );
  sl.registerFactory<ThemeCubit>(
    () => ThemeCubit(localStorage: sl<LocalStorage>()),
  );

  // ─── Route Guard ──────────────────────────────────────────
  sl.registerLazySingleton<AuthGuard>(
    () => AuthGuard(secureStorage: sl<SecureStorage>()),
  );

  // ═════════════════════════════════════════════════════════
  //  FEATURES
  // ═════════════════════════════════════════════════════════

  // ─── Auth ─────────────────────────────────────────────────
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl<SecureStorage>()),
  );
  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  // Use cases - Multi-flow authentication
  sl.registerLazySingleton(
    () => RegisterPatientUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => LookupEmailUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => GenerateLoginOtpUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => VerifyLoginOtpUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => GetSecurityQuestionsUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => SetupAccountUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => ConfirmOnboardingUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => FetchUserSecurityQuestionsUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => ActivateExistingUserUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => LogoutUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCurrentUserUseCase(repository: sl<AuthRepository>()),
  );
  sl.registerLazySingleton(
    () => RefreshTokenUseCase(repository: sl<AuthRepository>()),
  );
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      registerPatientUseCase: sl<RegisterPatientUseCase>(),
      lookupEmailUseCase: sl<LookupEmailUseCase>(),
      generateLoginOtpUseCase: sl<GenerateLoginOtpUseCase>(),
      verifyLoginOtpUseCase: sl<VerifyLoginOtpUseCase>(),
      getSecurityQuestionsUseCase: sl<GetSecurityQuestionsUseCase>(),
      setupAccountUseCase: sl<SetupAccountUseCase>(),
      confirmOnboardingUseCase: sl<ConfirmOnboardingUseCase>(),
      fetchUserSecurityQuestionsUseCase:
          sl<FetchUserSecurityQuestionsUseCase>(),
      activateExistingUserUseCase: sl<ActivateExistingUserUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      refreshTokenUseCase: sl<RefreshTokenUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ─── Appointments ─────────────────────────────────────────
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<AppointmentLocalDataSource>(
    () => AppointmentLocalDataSourceImpl(cache: sl<PersistentCache>()),
  );
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(
      remoteDataSource: sl<AppointmentRemoteDataSource>(),
      localDataSource: sl<AppointmentLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      cacheManager: sl<CacheManager>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetAppointmentsUseCase(repository: sl<AppointmentRepository>()),
  );
  sl.registerLazySingleton(
    () => BookAppointmentUseCase(repository: sl<AppointmentRepository>()),
  );
  sl.registerLazySingleton(
    () => CancelAppointmentUseCase(repository: sl<AppointmentRepository>()),
  );
  sl.registerFactory(
    () => AppointmentBloc(
      getAppointments: sl<GetAppointmentsUseCase>(),
      bookAppointment: sl<BookAppointmentUseCase>(),
      cancelAppointment: sl<CancelAppointmentUseCase>(),
    ),
  );

  // ─── Booking Wizard ───────────────────────────────────────
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      remoteDataSource: sl<BookingRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  // Note: BookingWizardCubit requires user context (patientId, branchId, etc.)
  // so it is created inline at the route level with BlocProvider rather than here.

  // ─── Tenants (public discovery for self-registration) ────
  sl.registerLazySingleton<TenantRemoteDataSource>(
    () => TenantRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<TenantRepository>(
    () => TenantRepositoryImpl(
      remoteDataSource: sl<TenantRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetPublicTenantsUseCase(repository: sl<TenantRepository>()),
  );
  sl.registerFactory<TenantCubit>(
    () => TenantCubit(
      getPublicTenants: sl<GetPublicTenantsUseCase>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );

  // ─── Medical Records ─────────────────────────────────────
  sl.registerLazySingleton<MedicalRecordRemoteDataSource>(
    () => MedicalRecordRemoteDataSourceImpl(
      dio: sl<Dio>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );
  sl.registerLazySingleton<MedicalRecordLocalDataSource>(
    () => MedicalRecordLocalDataSourceImpl(cache: sl<PersistentCache>()),
  );
  sl.registerLazySingleton<MedicalRecordRepository>(
    () => MedicalRecordRepositoryImpl(
      remoteDataSource: sl<MedicalRecordRemoteDataSource>(),
      localDataSource: sl<MedicalRecordLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      cacheManager: sl<CacheManager>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetMedicalRecordsUseCase(repository: sl<MedicalRecordRepository>()),
  );
  sl.registerFactory(
    () => MedicalRecordBloc(
      getMedicalRecords: sl<GetMedicalRecordsUseCase>(),
      repository: sl<MedicalRecordRepository>(),
    ),
  );

  // ─── Chat ─────────────────────────────────────────────────
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl<ChatRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetConversationsUseCase(repository: sl<ChatRepository>()),
  );
  sl.registerLazySingleton(
    () => GetMessagesUseCase(repository: sl<ChatRepository>()),
  );
  sl.registerLazySingleton(
    () => SendMessageUseCase(repository: sl<ChatRepository>()),
  );
  sl.registerFactory(
    () => ChatBloc(
      getConversations: sl<GetConversationsUseCase>(),
      getMessages: sl<GetMessagesUseCase>(),
      sendMessage: sl<SendMessageUseCase>(),
    ),
  );

  // ─── Notifications ────────────────────────────────────────
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(cache: sl<PersistentCache>()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl<NotificationRemoteDataSource>(),
      localDataSource: sl<NotificationLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      cacheManager: sl<CacheManager>(),
    ),
  );
  sl.registerLazySingleton(
    () => GetNotificationsUseCase(repository: sl<NotificationRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkNotificationReadUseCase(repository: sl<NotificationRepository>()),
  );
  sl.registerFactory(
    () => NotificationBloc(
      getNotifications: sl<GetNotificationsUseCase>(),
      markRead: sl<MarkNotificationReadUseCase>(),
      repository: sl<NotificationRepository>(),
    ),
  );

  // ─── Profile ──────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl<ProfileRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      repository: sl<ProfileRepository>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );

  // ─── Queue ────────────────────────────────────────────────
  sl.registerLazySingleton<QueueRemoteDataSource>(
    () => QueueRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<QueueRepository>(
    () => QueueRepositoryImpl(
      remoteDataSource: sl<QueueRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerFactory<QueueCubit>(
    () => QueueCubit(
      repository: sl<QueueRepository>(),
      secureStorage: sl<SecureStorage>(),
      signalR: sl<SignalRService>(),
    ),
  );

  // ─── Dispensations ──────────────────────────────────────────
  sl.registerLazySingleton<DispensationRemoteDataSource>(
    () => DispensationRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<DispensationRepository>(
    () => DispensationRepositoryImpl(
      remoteDataSource: sl<DispensationRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );
  sl.registerFactory<DispensationCubit>(
    () => DispensationCubit(
      repository: sl<DispensationRepository>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );

  // ─── Bills ────────────────────────────────────────────────
  sl.registerLazySingleton<BillRemoteDataSource>(
    () => BillRemoteDataSourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<BillRepository>(
    () => BillRepositoryImpl(
      remoteDataSource: sl<BillRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );
  sl.registerFactory<BillsCubit>(
    () => BillsCubit(
      repository: sl<BillRepository>(),
      secureStorage: sl<SecureStorage>(),
    ),
  );

  // ─── SignalR (singleton) ──────────────────────────────────────
  sl.registerLazySingleton<SignalRService>(
    () => SignalRService(secureStorage: sl<SecureStorage>()),
  );
}
