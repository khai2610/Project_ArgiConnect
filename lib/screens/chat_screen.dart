// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../screens/farmer/invoice_detail_screen.dart';
import '../models/chat_message.dart';
import '../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String farmerId;
  final String providerId;
  final String currentUserId;
  final String currentRole;
  final String token;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.farmerId,
    required this.providerId,
    required this.currentUserId,
    required this.currentRole,
    required this.token,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<ChatMessage> messages = [];
  bool loading = true;
  bool sending = false;

  Timer? _pollingTimer;
  String? _lastMsgId;

  @override
  void initState() {
    super.initState();
    _fetchMessages(initial: true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool initial = false}) async {
    try {
      final url = getChatBetweenUrl(widget.farmerId, widget.providerId);
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        final List data = body is List ? body : <dynamic>[];

        final parsed = data.map<ChatMessage>((e) {
          if (e is Map<String, dynamic>) return ChatMessage.fromJson(e);
          if (e is String) {
            try {
              final m = jsonDecode(e);
              if (m is Map<String, dynamic>) return ChatMessage.fromJson(m);
            } catch (_) {}
          }
          // fallback
          return ChatMessage.fromJson({
            '_id': '',
            'sender_id': '',
            'sender_role': '',
            'receiver_id': '',
            'receiver_role': '',
            'content': e.toString(),
            'createdAt': DateTime.now().toIso8601String(),
            'action': null
          });
        }).toList();

        final newLastId = parsed.isNotEmpty ? parsed.last.id : null;
        final hasNew = newLastId != null && newLastId != _lastMsgId;

        if (!mounted) return;
        setState(() {
          messages = parsed;
          loading = false;
          _lastMsgId = newLastId;
        });

        if (initial || hasNew) _jumpBottom();
      } else {
        if (!mounted) return;
        setState(() => loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _sendText(String text) async {
    final content = text.trim();
    if (content.isEmpty) return;

    setState(() => sending = true);
    try {
      final url = getChatBetweenUrl(widget.farmerId, widget.providerId);
      await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );
      _controller.clear();
      await _fetchMessages();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _jumpBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  String _fmtMoney(num? n) =>
      NumberFormat.decimalPattern('vi_VN').format(n ?? 0);

  String _fmtIso(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    return dt == null ? '—' : DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  void _openInvoiceDetail(String? invoiceId) async {
    if (invoiceId == null || invoiceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã hóa đơn.')),
      );
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/farmer/invoices/$invoiceId');
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final invoice = data['invoice'];

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(
              token: widget.token,
              invoice: invoice, // truyền full map
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải chi tiết hóa đơn')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi mở hóa đơn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi tải hóa đơn')),
      );
    }
  }


  Widget _invoiceCard(Map<String, dynamic> a) {
    final hasPayload = a['payload'] is Map<String, dynamic>;
    final p = hasPayload
        ? (a['payload'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final invoiceId = a['invoiceId']?.toString() ?? p['invoice_id']?.toString();
    final service =
        a['serviceType']?.toString() ?? p['service']?.toString() ?? '—';
    final due = a['dueDate']?.toString() ?? p['scheduled_at']?.toString();
    final amount = a['amount'] ?? p['amount'];
    final currency =
        a['currency']?.toString() ?? p['currency']?.toString() ?? 'VND';
    final cta = p['cta'] is Map<String, dynamic>
        ? p['cta'] as Map<String, dynamic>
        : null;

    final maxW = MediaQuery.of(context).size.width * 0.80;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe5e7eb)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bạn có một hóa đơn chưa thanh toán.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [const Text('🧰  '), Expanded(child: Text(service))]),
            if (due != null && due.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Text('📅  '),
                Expanded(child: Text(_fmtIso(due)))
              ]),
            ],
            const SizedBox(height: 4),
            Row(children: [
              const Text('💰  '),
              Text('${_fmtMoney(amount)} $currency')
            ]),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openInvoiceDetail(invoiceId),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cta?['label']?.toString() ?? 'Thanh toán ngay',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textBubble(String text, bool mine) {
    final maxW = MediaQuery.of(context).size.width * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? const Color(0xffDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe5e7eb)),
        ),
        child: Text(
          text,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage m, bool mine) {
    final a = m.action;
    if (a != null) {
      final type = a['type']?.toString();
      if (type == 'INVOICE_REMINDER' || type == 'INVOICE_CARD') {
        return _invoiceCard(a);
      }
    }
    return _textBubble(m.content, mine);
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final mine = m.senderId == myId;

                      // Dùng Align + ConstrainedBox để tránh tràn
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: _messageBubble(m, mine),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: messages.length,
                  ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendText,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn…',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: sending ? null : () => _sendText(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
