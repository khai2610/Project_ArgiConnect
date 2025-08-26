import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../chat_screen.dart';
import 'create_request_screen.dart'; // <- đảm bảo path đúng

class ProviderDetailScreen extends StatefulWidget {
  final String farmerId;
  final String providerId;
  final String token;

  const ProviderDetailScreen({
    required this.providerId,
    required this.farmerId,
    required this.token,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  late Future<Map<String, dynamic>> _providerFuture;
  late Future<List<dynamic>> _servicesFuture;
  late Future<List<dynamic>> _ratingsFuture;

  String? selectedService;

  @override
  void initState() {
    super.initState();
    _providerFuture = fetchProvider(widget.providerId);
    _servicesFuture = fetchServices(widget.providerId);
    _ratingsFuture = fetchRatings(widget.providerId);
  }

  // ===== Helpers =====

  String _serverOrigin() => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  String _resolveAvatarUrl(String? raw) {
    if (raw == null) return '';
    var v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http')) return v;
    v = v.replaceAll('\\', '/');
    final path = v.startsWith('/') ? v : '/$v';
    return '${_serverOrigin()}$path';
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  IconData _iconForService(String? name) {
    final s = (name ?? '').toLowerCase();
    if (s.contains('phun') || s.contains('thuốc')) return Icons.bug_report;
    if (s.contains('bón') || s.contains('phân')) return Icons.spa;
    if (s.contains('khảo') || s.contains('đất') || s.contains('khao sat'))
      return Icons.search;
    if (s.contains('gieo') || s.contains('hạt')) return Icons.agriculture;
    if (s.contains('tưới') || s.contains('nuoc') || s.contains('tưới tiêu'))
      return Icons.water_drop;
    return Icons.miscellaneous_services;
  }

  String _formatCurrency(dynamic v) {
    if (v == null) return '';
    final n = (v is num) ? v : num.tryParse(v.toString()) ?? 0;
    final s = n.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ',');
  }

  // ===== API =====

  Future<Map<String, dynamic>> fetchProvider(String id) async {
    final res = await http.get(Uri.parse(getPublicProviderInfoUrl(id)));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Không thể tải thông tin provider');
  }

  Future<List<dynamic>> fetchServices(String id) async {
    final res = await http.get(Uri.parse(getPublicProviderServicesUrl(id)));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Không thể tải danh sách dịch vụ');
  }

  Future<List<dynamic>> fetchRatings(String id) async {
    final res =
        await http.get(Uri.parse('$baseUrl/public/provider/$id/ratings'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // ===== UI pieces =====

  Widget _avatarHeader(Map<String, dynamic> p) {
    final name = (p['company_name'] ?? '') as String;
    final avatarUrl = _resolveAvatarUrl(p['avatar']?.toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.green.shade100,
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        _initials(name),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    )
                  : Text(
                      _initials(name),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Không rõ tên công ty' : name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Email: ${p['email'] ?? ''}'),
                Text('SĐT: ${p['phone'] ?? ''}'),
                Text('Địa chỉ: ${p['address'] ?? ''}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(Map<String, dynamic> s, Map<String, dynamic> provider) {
    final name = (s['name'] ?? '').toString();
    final desc = (s['description'] ?? '').toString();
    final price = s['price'] ??
        s['gia'] ??
        s['cost'] ??
        s['price_per_ha'] ??
        s['price_per_service'];
    final unit = (s['unit'] ?? (price != null ? 'VND/ha' : '')).toString();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ExpansionTile(
        key: PageStorageKey('service_$name'),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.green.shade50,
          child: Icon(_iconForService(name), color: Colors.green.shade700),
        ),
        title: Text(name),
        subtitle: desc.isNotEmpty
            ? Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        onExpansionChanged: (open) {
          if (open) setState(() => selectedService = name);
        },
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              const Icon(Icons.price_change, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  price == null
                      ? 'Chưa có báo giá'
                      : 'Giá: ${_formatCurrency(price)} $unit',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // 👉 Điều hướng sang CreateRequestScreen (đúng tên tham số)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateRequestScreen(
                      token: widget.token,
                      initialProviderId: widget.providerId,
                      initialServiceType: name,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700),
              child: const Text('Gửi yêu cầu'),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Thông tin nhà cung cấp'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([_providerFuture, _servicesFuture, _ratingsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final provider = (snapshot.data as List)[0] as Map<String, dynamic>;
          final services = (snapshot.data as List)[1] as List<dynamic>;
          final ratings = (snapshot.data as List)[2] as List<dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatarHeader(provider),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          farmerId: widget.farmerId,
                          providerId: widget.providerId,
                          currentUserId: widget.farmerId,
                          currentRole: farmerRole,
                          token: widget.token,
                          receiverName: provider['company_name'] ?? 'Đối tác',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Gửi tin nhắn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const Divider(height: 32),

                const Text('Dịch vụ cung cấp:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // ExpansionTile để xem giá + điều hướng
                ...services
                    .map((s) =>
                        _serviceCard(Map<String, dynamic>.from(s), provider))
                    .toList(),

                const SizedBox(height: 24),

                if (ratings.isNotEmpty) ...[
                  const Divider(height: 32),
                  const Text('Đánh giá từ nông dân:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...ratings.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Row(
                            children: List.generate(5, (index) {
                              final rating = r['rating'] ?? 0;
                              return Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.orange.shade400,
                                size: 20,
                              );
                            }),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((r['comment'] ?? '').toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Nhận xét: ${r['comment']}'),
                                ),
                              if (r['preferred_date'] != null)
                                Text(
                                    'Ngày: ${r['preferred_date'].toString().split('T')[0]}'),
                            ],
                          ),
                        ),
                      )),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text('Chưa có đánh giá nào từ nông dân'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
