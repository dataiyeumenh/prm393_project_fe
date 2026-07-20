import 'package:dio/dio.dart';

import '../models/api/chat_dto.dart';
import 'api_service.dart';

class ChatService {
  static Future<ApiResult<List<ChatSessionDTO>>> getSessions({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await ApiService.dio.get(
        '/api/v1/chat/sessions',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        final content = data is Map<String, dynamic> ? data['content'] : null;
        final sessions = (content is List)
            ? content
                  .whereType<Map<String, dynamic>>()
                  .map(ChatSessionDTO.fromJson)
                  .toList()
            : <ChatSessionDTO>[];
        return ApiResult.success(sessions);
      }

      return ApiResult.fail(_extractError(response.data));
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<ChatSessionDTO>> createSession() async {
    try {
      final response = await ApiService.dio.post('/api/v1/chat/sessions');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        if (data is Map<String, dynamic>) {
          return ApiResult.success(ChatSessionDTO.fromJson(data));
        }
      }
      return ApiResult.fail('Không thể tạo phiên chat mới');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<List<ChatMessageDTO>>> getMessages(
    String sessionId,
  ) async {
    try {
      final response = await ApiService.dio.get(
        '/api/v1/chat/sessions/$sessionId/messages',
      );
      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        final messages = (data is List)
            ? data
                  .whereType<Map<String, dynamic>>()
                  .map(ChatMessageDTO.fromJson)
                  .toList()
            : <ChatMessageDTO>[];
        return ApiResult.success(messages);
      }
      return ApiResult.fail(_extractError(response.data));
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static Future<ApiResult<ChatSendResponseDTO>> sendMessage({
    required String sessionId,
    required String content,
  }) async {
    try {
      final response = await ApiService.dio.post(
        '/api/v1/chat/sessions/$sessionId/messages',
        data: {'content': content},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        if (data is Map<String, dynamic>) {
          return ApiResult.success(ChatSendResponseDTO.fromJson(data));
        }
      }

      return ApiResult.fail('Không thể gửi tin nhắn');
    } catch (e) {
      return ApiResult.fail(_extractError(e));
    }
  }

  static String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      final code = e.response?.statusCode;
      if (code != null) return 'Lỗi máy chủ ($code)';
    }

    if (e is Map<String, dynamic>) {
      final msg = e['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }

    return 'Có lỗi xảy ra, vui lòng thử lại';
  }
}

class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult._({this.data, this.error, required this.isSuccess});

  factory ApiResult.success(T data) => ApiResult._(data: data, isSuccess: true);

  factory ApiResult.fail(String error) =>
      ApiResult._(error: error, isSuccess: false);
}
