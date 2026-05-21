import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/injection_container.dart';
import '../features/appointments/data/models/my_appointment_dto.dart';
import '../features/appointments/domain/repositories/booking_repository.dart';
import '../features/appointments/presentation/bloc/booking_cubit.dart';
import '../features/appointments/presentation/bloc/appointment_bloc.dart';
import '../features/appointments/presentation/bloc/appointment_event.dart';
import '../features/appointments/presentation/pages/appointment_detail_page.dart';
import '../features/appointments/presentation/pages/appointment_list_page.dart';
import '../features/appointments/presentation/pages/booking_wizard_page.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/chat/presentation/pages/chat_detail_page.dart';
import '../features/chat/presentation/pages/conversation_list_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/medical_records/domain/entities/medical_record_entity.dart';
import '../features/medical_records/presentation/pages/medical_record_detail_page.dart';
import '../features/medical_records/presentation/pages/medical_record_list_page.dart';
import '../features/bills/presentation/pages/bill_detail_page.dart';
import '../features/bills/presentation/pages/bills_list_page.dart';
import '../features/dispensations/presentation/pages/dispensations_page.dart';
import '../features/orders/presentation/pages/order_detail_page.dart';
import '../features/orders/presentation/pages/orders_list_page.dart';
import '../features/notifications/presentation/pages/notification_list_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/queue/presentation/pages/queue_live_page.dart';
import '../features/tenants/presentation/pages/tenant_select_page.dart';

/// Named route constants used throughout the app.
class Routes {
  Routes._();

  static const String auth = '/auth';
  static const String selectTenant = '/auth/select-tenant';
  static const String dashboard = '/dashboard';
  static const String appointments = '/appointments';
  static const String bookAppointment = '/appointments/book';
  static const String appointmentDetail = '/appointments/detail';
  static const String medicalRecords = '/medical-records';
  static const String medicalRecordDetail = '/medical-records/detail';
  static const String conversations = '/chat';
  static const String chatDetail = '/chat/detail';
  static const String notifications = '/notifications';

  static const String profile = '/profile';
  static const String queueLive = '/queue';
  static const String dispensations = '/dispensations';
  static const String bills = '/bills';
  static const String billDetail = '/bills/detail';

  static const String ordersList = '/orders';
  static const String orderDetail = '/orders/detail';
}

/// Central route generator. Pass as [onGenerateRoute] to [MaterialApp].
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.auth:
        return _page(const AuthPage());

      case Routes.selectTenant:
        return _page(const TenantSelectPage());

      case Routes.dashboard:
        return _page(const DashboardPage());

      case Routes.appointments:
        return _page(
          BlocProvider<AppointmentBloc>(
            create: (_) => sl<AppointmentBloc>()..add(AppointmentsLoaded()),
            child: const AppointmentListPage(),
          ),
        );

      case Routes.bookAppointment:
        return MaterialPageRoute(
          builder: (routeContext) {
            // Extract user context from the nearest AuthBloc.
            final authState = routeContext.read<AuthBloc>().state;
            UserEntity? user;
            if (authState is AuthAuthenticated) {
              user = authState.user;
            }
            return BlocProvider(
              create: (_) => BookingWizardCubit(
                repository: sl<BookingRepository>(),
                patientId: user?.patientId ?? '',
                branchId: user?.branchId ?? '',
                tenantId: user?.tenantId ?? '',
                patientName: user?.fullName ?? '',
              ),
              child: const BookingWizardPage(),
            );
          },
        );

      case Routes.appointmentDetail:
        final appointment = settings.arguments as MyAppointmentDto;
        return MaterialPageRoute(
          builder: (_) => BlocProvider<AppointmentBloc>(
            create: (_) => sl<AppointmentBloc>(),
            child: AppointmentDetailPage(appointment: appointment),
          ),
        );

      case Routes.medicalRecords:
        return _page(const MedicalRecordListPage());

      case Routes.medicalRecordDetail:
        final record = settings.arguments as MedicalRecordEntity;
        return _page(MedicalRecordDetailPage(record: record));

      case Routes.conversations:
        return _page(const ConversationListPage());

      case Routes.chatDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _page(
          ChatDetailPage(
            conversationId: args['conversationId'] as String,
            doctorName: args['doctorName'] as String,
          ),
        );

      case Routes.notifications:
        return _page(const NotificationListPage());

      case Routes.profile:
        return _page(const ProfilePage());

      case Routes.queueLive:
        return _page(const QueueLivePage());

      case Routes.dispensations:
        return _page(const DispensationsPage());

      case Routes.bills:
        return _page(const BillsListPage());

      case Routes.billDetail:
        final billId = settings.arguments as String;
        return _page(BillDetailPage(billId: billId));

      case Routes.ordersList:
        final appointmentId = settings.arguments as String;
        return _page(OrdersListPage(appointmentId: appointmentId));

      case Routes.orderDetail:
        final orderId = settings.arguments as String;
        return _page(OrderDetailPage(orderId: orderId));

      default:
        return _page(const AuthPage());
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child) {
    return MaterialPageRoute<T>(builder: (_) => child);
  }
}
