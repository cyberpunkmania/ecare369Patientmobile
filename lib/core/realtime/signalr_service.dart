import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../config/env_config.dart';
import '../storage/secure_storage.dart';

/// Thin wrapper around the `signalr_netcore` [HubConnection] that streams
/// strongly-named events to the rest of the app. Auto-reconnects with a
/// constant retry strategy and lazily starts on first listener.
class SignalRService {
  final SecureStorage secureStorage;

  HubConnection? _connection;
  Future<void>? _starting;

  final StreamController<QueueUpdatedEvent> _queue =
      StreamController.broadcast();
  final StreamController<PatientCalledEvent> _called =
      StreamController.broadcast();
  final StreamController<AppointmentReminderEvent> _reminder =
      StreamController.broadcast();
  final StreamController<PaymentReceivedEvent> _payment =
      StreamController.broadcast();
  final StreamController<PrescriptionReadyEvent> _rx =
      StreamController.broadcast();
  final StreamController<ChatMessageEvent> _chat = StreamController.broadcast();
  final StreamController<ChatTypingEvent> _typing =
      StreamController.broadcast();
  final StreamController<NotificationPushEvent> _notif =
      StreamController.broadcast();

  SignalRService({required this.secureStorage});

  Stream<QueueUpdatedEvent> get queueUpdates => _queue.stream;
  Stream<PatientCalledEvent> get patientCalled => _called.stream;
  Stream<AppointmentReminderEvent> get appointmentReminders => _reminder.stream;
  Stream<PaymentReceivedEvent> get paymentReceived => _payment.stream;
  Stream<PrescriptionReadyEvent> get prescriptionReady => _rx.stream;
  Stream<ChatMessageEvent> get chatMessages => _chat.stream;
  Stream<ChatTypingEvent> get chatTyping => _typing.stream;
  Stream<NotificationPushEvent> get notifications => _notif.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> ensureStarted() async {
    if (isConnected) return;
    _starting ??= _start();
    return _starting;
  }

  Future<void> _start() async {
    try {
      final token = await secureStorage.getAuthToken();
      final url = EnvConfig.notificationHubUrl;
      final connection = HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token ?? '',
            ),
          )
          .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
          .build();

      _wire(connection);
      await connection.start();
      _connection = connection;
    } catch (_) {
      _starting = null;
      rethrow;
    }
  }

  void _wire(HubConnection c) {
    c.on('QueueUpdated', (args) {
      final m = _asMap(args);
      if (m != null) _queue.add(QueueUpdatedEvent.fromJson(m));
    });
    c.on('PatientCalled', (args) {
      final m = _asMap(args);
      if (m != null) _called.add(PatientCalledEvent.fromJson(m));
    });
    c.on('AppointmentReminder', (args) {
      final m = _asMap(args);
      if (m != null) _reminder.add(AppointmentReminderEvent.fromJson(m));
    });
    c.on('PaymentReceived', (args) {
      final m = _asMap(args);
      if (m != null) _payment.add(PaymentReceivedEvent.fromJson(m));
    });
    c.on('PrescriptionReady', (args) {
      final m = _asMap(args);
      if (m != null) _rx.add(PrescriptionReadyEvent.fromJson(m));
    });
    c.on('ReceiveMessage', (args) {
      final m = _asMap(args);
      if (m != null) _chat.add(ChatMessageEvent.fromJson(m));
    });
    c.on('UserTyping', (args) {
      final m = _asMap(args);
      if (m != null) _typing.add(ChatTypingEvent.fromJson(m));
    });
    c.on('Notification', (args) {
      final m = _asMap(args);
      if (m != null) _notif.add(NotificationPushEvent.fromJson(m));
    });
  }

  Map<String, dynamic>? _asMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final first = args.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
    return null;
  }

  Future<void> stop() async {
    try {
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
    _starting = null;
  }
}

// ─── Event payloads ──────────────────────────────────────────

class QueueUpdatedEvent {
  final String branchId;
  final int waitingCount;
  final int inServiceCount;
  final DateTime? at;
  QueueUpdatedEvent({
    required this.branchId,
    required this.waitingCount,
    required this.inServiceCount,
    this.at,
  });
  factory QueueUpdatedEvent.fromJson(Map<String, dynamic> j) =>
      QueueUpdatedEvent(
        branchId: j['branchId']?.toString() ?? '',
        waitingCount: (j['waitingCount'] as num?)?.toInt() ?? 0,
        inServiceCount: (j['inServiceCount'] as num?)?.toInt() ?? 0,
        at: j['at'] != null ? DateTime.tryParse(j['at'].toString()) : null,
      );
}

class PatientCalledEvent {
  final String patientId;
  final String? counterName;
  final String? doctorName;
  PatientCalledEvent({
    required this.patientId,
    this.counterName,
    this.doctorName,
  });
  factory PatientCalledEvent.fromJson(Map<String, dynamic> j) =>
      PatientCalledEvent(
        patientId: j['patientId']?.toString() ?? '',
        counterName: j['counterName']?.toString(),
        doctorName: j['doctorName']?.toString(),
      );
}

class AppointmentReminderEvent {
  final String appointmentId;
  final DateTime when;
  final String? doctorName;
  AppointmentReminderEvent({
    required this.appointmentId,
    required this.when,
    this.doctorName,
  });
  factory AppointmentReminderEvent.fromJson(Map<String, dynamic> j) =>
      AppointmentReminderEvent(
        appointmentId: j['appointmentId']?.toString() ?? '',
        when: DateTime.tryParse(j['when']?.toString() ?? '') ?? DateTime.now(),
        doctorName: j['doctorName']?.toString(),
      );
}

class PaymentReceivedEvent {
  final String billId;
  final num amount;
  PaymentReceivedEvent({required this.billId, required this.amount});
  factory PaymentReceivedEvent.fromJson(Map<String, dynamic> j) =>
      PaymentReceivedEvent(
        billId: j['billId']?.toString() ?? '',
        amount: (j['amount'] as num?) ?? 0,
      );
}

class PrescriptionReadyEvent {
  final String prescriptionId;
  final String? medicationName;
  PrescriptionReadyEvent({required this.prescriptionId, this.medicationName});
  factory PrescriptionReadyEvent.fromJson(Map<String, dynamic> j) =>
      PrescriptionReadyEvent(
        prescriptionId: j['prescriptionId']?.toString() ?? '',
        medicationName: j['medicationName']?.toString(),
      );
}

class ChatMessageEvent {
  final String roomId;
  final String messageId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  ChatMessageEvent({
    required this.roomId,
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });
  factory ChatMessageEvent.fromJson(Map<String, dynamic> j) => ChatMessageEvent(
    roomId: j['roomId']?.toString() ?? '',
    messageId: j['messageId']?.toString() ?? j['id']?.toString() ?? '',
    senderId: j['senderId']?.toString() ?? '',
    content: j['content']?.toString() ?? '',
    sentAt: DateTime.tryParse(j['sentAt']?.toString() ?? '') ?? DateTime.now(),
  );
}

class ChatTypingEvent {
  final String roomId;
  final String userId;
  final bool isTyping;
  ChatTypingEvent({
    required this.roomId,
    required this.userId,
    required this.isTyping,
  });
  factory ChatTypingEvent.fromJson(Map<String, dynamic> j) => ChatTypingEvent(
    roomId: j['roomId']?.toString() ?? '',
    userId: j['userId']?.toString() ?? '',
    isTyping: j['isTyping'] as bool? ?? false,
  );
}

class NotificationPushEvent {
  final String id;
  final String title;
  final String body;
  final String? type;
  final DateTime at;
  NotificationPushEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.type,
  });
  factory NotificationPushEvent.fromJson(Map<String, dynamic> j) =>
      NotificationPushEvent(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        type: j['type']?.toString(),
        at: DateTime.tryParse(j['at']?.toString() ?? '') ?? DateTime.now(),
      );
}
