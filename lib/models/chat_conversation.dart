class ChatConversation {
  final String farmerId;
  final String providerId;
  final String partnerName;
  final String lastMessage;
  final DateTime updatedAt;

  ChatConversation({
    required this.farmerId,
    required this.providerId,
    required this.partnerName,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      farmerId: json['farmer_id'],
      providerId: json['provider_id'],
      partnerName: json['partner_name'],
      lastMessage: json['last_message'] ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
