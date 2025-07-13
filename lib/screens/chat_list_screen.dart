import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/chat_conversation.dart';
import '../screens/chat_screen.dart';
import '../utils/constants.dart'; // ✅ import constants chứa URL API

class ChatListScreen extends StatefulWidget {
  final String token;
  final String currentUserId;
  final String currentRole;

  const ChatListScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.currentRole,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatConversation> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    try {
      final res = await http.get(
        Uri.parse(chatConversationsUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          conversations =
              data.map((e) => ChatConversation.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        print('❌ Lỗi API: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('❌ Lỗi kết nối: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tin nhắn")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
              ? const Center(child: Text("Không có cuộc hội thoại nào"))
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (ctx, i) {
                    final convo = conversations[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.chat)),
                      title: Text(convo.partnerName),
                      subtitle: Text(convo.lastMessage),
                      trailing: Text(
                        "${convo.updatedAt.hour.toString().padLeft(2, '0')}:${convo.updatedAt.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              requestId: convo.requestId,
                              currentUserId: widget.currentUserId,
                              currentRole: widget.currentRole,
                              token: widget.token,
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
