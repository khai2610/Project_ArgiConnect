import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../utils/constants.dart'; // ✅ dùng constants chuẩn

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final String currentRole;
  final String token;
  final String? receiverId; // bạn có thể truyền vào nếu biết từ trước

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.currentUserId,
    required this.currentRole,
    required this.token,
    this.receiverId, // optional
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    fetchMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchMessages();
    });
  }

  Future<void> fetchMessages() async {
    try {
      final res = await http.get(
        Uri.parse(getChatMessagesUrl(widget.requestId)),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        setState(() {
          messages = data.map((e) => ChatMessage.fromJson(e)).toList();
        });
      } else {
        print('❌ Lỗi fetchMessages: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('❌ Lỗi kết nối: $e');
    }
  }

  Future<void> sendMessage(String content) async {
    if (widget.receiverId == null) {
      print('❗️Không có receiverId để gửi tin nhắn.');
      return;
    }

    final res = await http.post(
      Uri.parse(sendMessageUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'request_id': widget.requestId,
        'receiver_id': widget.receiverId,
        'receiver_role': widget.currentRole == 'farmer' ? 'provider' : 'farmer',
        'content': content,
      }),
    );

    if (res.statusCode == 201) {
      _controller.clear();
      fetchMessages(); // load lại
    } else {
      print('❌ Gửi tin nhắn lỗi: ${res.statusCode} - ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (ctx, index) {
                final msg = messages[index];
                final isMe = msg.senderId == widget.currentUserId;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.content),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Nhập tin nhắn...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(_controller.text.trim());
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
