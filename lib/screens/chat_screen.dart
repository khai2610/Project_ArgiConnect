import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String farmerId;
  final String providerId;
  final String currentUserId;
  final String currentRole;
  final String token;

  const ChatScreen({
    super.key,
    required this.farmerId,
    required this.providerId,
    required this.currentUserId,
    required this.currentRole,
    required this.token,
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchMessages();
    });
  }

  Future<void> fetchMessages() async {
    final url = getChatBetweenUrl(widget.farmerId, widget.providerId);
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      setState(() {
        messages = data.map((e) => ChatMessage.fromJson(e)).toList();
      });
    } else {
      print('❌ Lỗi fetch: ${res.statusCode} - ${res.body}');
    }
  }

  Future<void> sendMessage(String content) async {
    final url = getChatBetweenUrl(widget.farmerId, widget.providerId);

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({'content': content}),
    );

    if (res.statusCode == 201) {
      _controller.clear();
      fetchMessages();
    } else {
      print('❌ Lỗi gửi: ${res.statusCode} - ${res.body}');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('chat')),
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
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    padding: const EdgeInsets.all(10),
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
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
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
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
