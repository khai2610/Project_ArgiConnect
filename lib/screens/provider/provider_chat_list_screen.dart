import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../utils/constants.dart';
import 'provider_chat_screen.dart';

class ProviderChatListScreen extends StatefulWidget {
  final String token;

  const ProviderChatListScreen({super.key, required this.token});

  @override
  State<ProviderChatListScreen> createState() => _ProviderChatListScreenState();
}

class _ProviderChatListScreenState extends State<ProviderChatListScreen> {
  List conversations = [];

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    final response = await http.get(
      Uri.parse(chatConversationsUrl),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        conversations = json.decode(response.body);
      });
    } else {
      print('❌ Lỗi tải cuộc trò chuyện: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final convo = conversations[index];

          final farmerId = convo['farmerId'] ?? '';
          final providerId = convo['providerId'] ?? '';
          final receiverName = convo['partner_name'] ?? 'Đối tác';
          final lastMessage = convo['last_message'] ?? '';
          final updatedRaw = convo['updated_at'];

          DateTime updatedAt;
          try {
            updatedAt = DateTime.parse(updatedRaw);
          } catch (_) {
            updatedAt = DateTime.now();
          }

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(receiverName),
            subtitle: Text(lastMessage),
            trailing: Text(
              "${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderChatScreen(
                    token: widget.token,
                    farmerId: convo['farmerId'],
                    providerId: convo['providerId'],
                    currentUserId: convo['providerId'],
                    receiverName: convo['partner_name'],
                  ),
                ),
              );

            },
          );
        },
      ),
    );
  }
}
