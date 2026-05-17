import '../../domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.doctorId,
    required super.doctorName,
    super.doctorAvatarUrl,
    super.lastMessage,
    super.lastMessageAt,
    super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? 'Doctor',
      doctorAvatarUrl: json['doctorAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'doctorAvatarUrl': doctorAvatarUrl,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'unreadCount': unreadCount,
  };
}
