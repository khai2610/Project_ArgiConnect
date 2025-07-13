// models/chat_message.dart
class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'],
      senderId: json['sender_id'],
      senderRole: json['sender_role'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
