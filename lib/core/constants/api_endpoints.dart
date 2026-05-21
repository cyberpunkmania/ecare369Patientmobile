/// Single source of truth for every backend route the patient mobile app
/// consumes. Paths were verified end-to-end against the Identity, Pharmacy
/// and Notifications APIs.
///
/// Convention: all string constants are plain paths (no host). The host is
/// supplied by [EnvConfig.baseUrl] via the Dio instance.
class ApiEndpoints {
  ApiEndpoints._();

  // ───────────────────────────── Tenants (discovery) ─────────────────────────
  /// GET — public list of active tenants (branding-only projection).
  /// Used by the "Select your clinic group" step before self-registration.
  static const String tenantsPublic = '/api/tenants/public';

  /// GET — single tenant by id (anonymous).
  static String tenantById(String tenantId) => '/api/tenants/$tenantId';

  // ───────────────────────────── Patient Registration ────────────────────────
  /// POST — anonymous self-registration. Body: RegisterPatientRequest with
  /// `tenantId` chosen by the user.
  static const String patientRegister = '/api/patients/public/register';

  // ───────────────────────────── Auth (multi-flow) ───────────────────────────
  static const String authLookup = '/api/auth/lookup';
  static const String authGenerateLoginOtp = '/api/auth/generate-login-otp';
  static const String authVerifyLoginOtp = '/api/auth/verify-login-otp';
  static const String authSecurityQuestions = '/api/auth/security-questions';
  static const String authSetupAccount = '/api/auth/setup-account';
  static const String authConfirmOnboarding = '/api/auth/confirm-onboarding';
  static const String authFetchSecurityQuestions =
      '/api/auth/fetch-security-questions';
  static const String authActivateExistingUser =
      '/api/auth/activate-existing-user';
  static const String authRefresh = '/api/auth/refresh';
  static const String authLogout = '/api/auth/logout';
  static const String authMe = '/api/auth/me';

  // ───────────────────────────── Patient profile ─────────────────────────────
  /// GET — full PatientDto (incl. insurances[]).
  static String patientById(String patientId) => '/api/patients/$patientId';

  /// PUT — update demographics (DOB / gender / address).
  static String patientDemographics(String patientId) =>
      '/api/patients/$patientId/demographics';

  /// PUT — update emergency contact.
  static String patientEmergencyContact(String patientId) =>
      '/api/patients/$patientId/emergency-contact';

  /// POST — add an insurance policy on a patient profile.
  static String patientAddInsurance(String patientId) =>
      '/api/patients/$patientId/insurances';

  /// PUT — update an existing insurance policy on a patient profile.
  static String patientUpdateInsurance(String patientId, String insuranceId) =>
      '/api/patients/$patientId/insurances/$insuranceId';

  /// DELETE — remove an insurance policy from a patient profile.
  static String patientRemoveInsurance(String patientId, String insuranceId) =>
      '/api/patients/$patientId/insurances/$insuranceId';

  /// GET — full clinical history (consultations, SOAP, vitals, diagnoses,
  /// prescriptions, investigations). Single source for the "Records" tab.
  static String patientClinicalHistory(String patientId) =>
      '/api/patients/$patientId/clinical-history';

  // ───────────────────────────── Branches & doctors ──────────────────────────
  static const String branches = '/api/branches';
  static String branchById(String branchId) => '/api/branches/$branchId';
  static String branchPaymentOptions(String branchId) =>
      '/api/branches/$branchId/payment-options';

  /// GET — active doctors (auto-scoped to caller's tenant). Supports query
  /// params `branchId`, `specialty`, `status`, `pageSize`.
  static const String doctors = '/api/doctors';
  static String doctorById(String doctorId) => '/api/doctors/$doctorId';

  // ───────────────────────────── Schedules / slots ───────────────────────────
  static String schedulesByBranch(String branchId) =>
      '/api/schedules/branch/$branchId';
  static String availableDoctors(String branchId) =>
      '/api/schedules/branch/$branchId/available-doctors';
  static String scheduleByDoctorBranch(String doctorId, String branchId) =>
      '/api/schedules/doctor/$doctorId/branch/$branchId';
  static String slotRange(String scheduleId) =>
      '/api/schedules/$scheduleId/slots/range';
  static String slotsForDate(String scheduleId) =>
      '/api/schedules/$scheduleId/slots';
  static String holdSlot(String scheduleId, String slotId) =>
      '/api/schedules/$scheduleId/slots/$slotId/hold';
  static String releaseSlot(String scheduleId, String slotId) =>
      '/api/schedules/$scheduleId/slots/$slotId/hold';

  // ───────────────────────────── Appointments ────────────────────────────────
  /// POST — confirm booking after holding a slot.
  static const String createAppointment = '/api/appointments';

  /// GET — paginated list of the caller's own appointments.
  static const String myAppointments = '/api/appointments/my';

  static String appointmentById(String id) => '/api/appointments/$id';
  static String rescheduleAppointment(String id) =>
      '/api/appointments/$id/reschedule';
  static String cancelAppointment(String id) => '/api/appointments/$id/cancel';

  // ───────────────────────────── Queue (clinical workflow) ───────────────────
  /// GET — full live snapshot of the clinic floor (waiting / in-service /
  /// doctor counters). Use for the carousel display.
  static String queueLiveByBranch(String branchId) =>
      '/api/queues/branch/$branchId/live';

  /// GET — the caller-patient's own ETA + position card.
  /// Query: `patientId={guid}` and optional `date=YYYY-MM-DD`.
  static String queueMyPosition(String branchId) =>
      '/api/queues/branch/$branchId/my-position';

  // ───────────────────────────── Pharmacy (filled scripts) ───────────────────
  /// GET — paged list of dispensations for a patient (issued prescriptions
  /// that the pharmacy has actually filled).
  static String pharmacyDispensationsByPatient(String patientId) =>
      '/api/pharmacy/dispensations/patient/$patientId';

  /// GET — patient portal: own dispensation history (uses JWT PatientId).
  static const String pharmacyDispensationsMy =
      '/api/pharmacy/dispensations/my';

  // ───────────────────────────── Bills ───────────────────────────────────────
  /// GET — paged bills for a patient (staff: requires BILL.READ).
  static String billsByPatient(String patientId) =>
      '/api/bills/patient/$patientId';

  /// GET — patient portal: own bills (uses JWT PatientId, requires BILL.READ.SELF).
  static const String billsMy = '/api/bills/my';

  /// GET — single bill detail (line items + payments).
  static String billById(String billId) => '/api/bills/$billId';

  /// GET — patient portal: download own bill as PDF (requires BILL.READ.SELF).
  static String billPdfMy(String billId) => '/api/bills/$billId/pdf/my';

  // ───────────────────────────── Insurance catalog ───────────────────────────
  static const String insuranceProviders = '/api/insurance/providers';
  static const String insuranceSchemesActive = '/api/insurance/schemes/active';

  // ───────────────────────────── Notifications service ───────────────────────
  /// All chat + push live on the separate `Ecare.Notifications.API`, but
  /// share the same host in single-deployment topology.
  static const String pushNotifications = '/api/push-notifications';
  static const String pushNotificationsUnread =
      '/api/push-notifications/unread';
  static const String pushNotificationsUnreadCount =
      '/api/push-notifications/unread/count';
  static String markPushNotificationRead(String id) =>
      '/api/push-notifications/$id/mark-read';
  static const String markAllPushNotificationsRead =
      '/api/push-notifications/mark-all-read';

  // ───────────────────────────── Chat ────────────────────────────────────────
  static const String chatRooms = '/api/chat-rooms';
  static String chatRoomById(String roomId) => '/api/chat-rooms/$roomId';
  static String chatRoomMessages(String roomId) =>
      '/api/chat-rooms/$roomId/messages';

  /// Base path used for POST `/api/chat-messages` (body carries `roomId`,
  /// `receiverId`, `content`).
  static const String chatMessagesBase = '/api/chat-messages';
  static String chatConversationWith(String userId) =>
      '/api/chat-messages/conversation/$userId';
  static String markChatMessageRead(String messageId) =>
      '/api/chat-messages/$messageId/mark-read';

  // ───────────────────────────── Orders / Service Requests ──────────────────
  /// GET — all service requests for a specific appointment.
  /// Returns `ListResponse<ServiceRequestDto>`.
  static String ordersByAppointment(String appointmentId) =>
      '/api/orders/service-requests/appointment/$appointmentId';

  /// GET — single service request detail (incl. results + attachments).
  static String orderById(String orderId) =>
      '/api/orders/service-requests/$orderId';

  // ───────────────────────────── Back-compat aliases ─────────────────────────
  // Kept temporarily so existing datasources compile while we migrate them
  // one-by-one. New code should reference the canonical names above.

  /// @deprecated use [patientById]
  static String patientProfile(String patientId) => patientById(patientId);

  /// @deprecated use [createAppointment]
  static const String bookAppointment = createAppointment;

  /// @deprecated use [chatRooms]
  static const String chatConversations = chatRooms;

  /// @deprecated use [chatRoomMessages]
  static String chatMessages(String roomId) => chatRoomMessages(roomId);

  /// @deprecated use [chatMessagesBase] (POST with body containing roomId)
  static String sendMessage(String roomId) => chatRoomMessages(roomId);

  /// @deprecated use [pushNotifications]
  static const String notifications = pushNotifications;

  /// @deprecated use [markPushNotificationRead]
  static String markNotificationRead(String id) => markPushNotificationRead(id);

  /// @deprecated use [markAllPushNotificationsRead]
  static const String markAllNotificationsRead = markAllPushNotificationsRead;

  /// @deprecated reachable only via the third-party-integrations group; the
  /// patient JWT flow does not currently support self-initiating a payment.
  static const String paymentInitiate =
      '/api/third-party-client-integrations/payments/initiate';

  /// @deprecated alias for [doctors]
  static const String activeDoctorsList = doctors;
}
