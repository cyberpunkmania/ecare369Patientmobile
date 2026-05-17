import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio _dio;

  ChatRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _dio.get(ApiEndpoints.chatConversations);
      final data = response.data;
      final List list = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      return list
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.chatMessages(conversationId),
      );
      final data = response.data;
      final List list = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      return list
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.chatMessagesBase,
        data: {'roomId': conversationId, 'content': content, 'type': type},
      );
      final body = response.data;
      final payload = body is Map<String, dynamic>
          ? (body['data'] as Map<String, dynamic>? ?? body)
          : <String, dynamic>{};
      return MessageModel.fromJson(payload);
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  ServerException _extract(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;
    return ServerException(
      message: e.message ?? 'Unknown error',
      statusCode: e.response?.statusCode,
    );
  }
}
