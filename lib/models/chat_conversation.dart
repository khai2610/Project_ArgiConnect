// models/chat_conversation.dart
class ChatConversation {
  final String requestId;
  final String partnerName;
  final String lastMessage;
  final DateTime updatedAt;

  ChatConversation({
    required this.requestId,
    required this.partnerName,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      requestId: json['request_id'],
      partnerName:
          json['provider_name'], // hoặc farmer_name nếu bạn là provider
      lastMessage: json['last_message'] ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
