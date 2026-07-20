class ChatSessionDTO {
  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatSessionDTO({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatSessionDTO.fromJson(Map<String, dynamic> json) {
    return ChatSessionDTO(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Chat session',
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

class ChatMessageDTO {
  final String id;
  final String role;
  final String content;
  final DateTime? createdAt;

  ChatMessageDTO({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
  });

  bool get isUser {
    final r = role.toLowerCase();
    return r.contains('user') || r == 'human' || r == 'client';
  }

  factory ChatMessageDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageDTO(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

class ChatSendResponseDTO {
  final String sessionId;
  final ChatMessageDTO? userMessage;
  final ChatMessageDTO? aiMessage;
  final List<ChatMessageDTO> allMessages;
  final List<String> recommendedProductIds;

  ChatSendResponseDTO({
    required this.sessionId,
    required this.userMessage,
    required this.aiMessage,
    required this.allMessages,
    required this.recommendedProductIds,
  });

  factory ChatSendResponseDTO.fromJson(Map<String, dynamic> json) {
    final dynamic messagesRaw =
        json['allMessages'] ?? json['allMessage'] ?? json['messages'];

    final allMessages = (messagesRaw is List)
        ? messagesRaw
              .whereType<Map<String, dynamic>>()
              .map(ChatMessageDTO.fromJson)
              .toList()
        : <ChatMessageDTO>[];

    final dynamic recRaw = json['recommendedProductIds'];
    final recommendedProductIds = (recRaw is List)
        ? recRaw.map((e) => e.toString()).toList()
        : <String>[];

    return ChatSendResponseDTO(
      sessionId: json['sessionId']?.toString() ?? '',
      userMessage: _toMessage(json['userMessage']),
      aiMessage: _toMessage(json['aiMessage']),
      allMessages: allMessages,
      recommendedProductIds: recommendedProductIds,
    );
  }

  static ChatMessageDTO? _toMessage(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ChatMessageDTO.fromJson(raw);
    }
    return null;
  }
}

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
