// lib/models/chat_message.dart
import 'dart:convert';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String receiverId;
  final String receiverRole;
  final String content;
  final Map<String, dynamic>? action; // <- Map hoặc null
  final bool read;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.receiverId,
    required this.receiverRole,
    required this.content,
    required this.createdAt,
    this.action,
    this.read = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Parse action linh hoạt (Map | String | null)
    Map<String, dynamic>? parsedAction;
    final raw = json['action'];
    if (raw == null) {
      parsedAction = null;
    } else if (raw is Map<String, dynamic>) {
      parsedAction = raw;
    } else if (raw is String) {
      // thử JSON decode; nếu không được thì bọc vào PLAINTEXT
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          parsedAction = decoded;
        } else {
          parsedAction = {'type': 'PLAINTEXT', 'text': raw};
        }
      } catch (_) {
        parsedAction = {'type': 'PLAINTEXT', 'text': raw};
      }
    } else {
      parsedAction = null;
    }

    DateTime created;
    try {
      created = DateTime.parse(json['createdAt'] ?? '');
    } catch (_) {
      created = DateTime.now();
    }

    return ChatMessage(
      id: (json['_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      senderRole: (json['sender_role'] ?? '').toString(),
      receiverId: (json['receiver_id'] ?? '').toString(),
      receiverRole: (json['receiver_role'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      action: parsedAction,
      read: json['read'] == true,
      createdAt: created,
    );
  }
}
