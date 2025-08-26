import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'provider_detail_screen.dart';
import 'ServiceProvidersMapScreen.dart';

class ApprovedProvidersScreen extends StatefulWidget {
  final String token;
  final String farmerId;

  const ApprovedProvidersScreen({
    Key? key,
    required this.token,
    required this.farmerId,
  }) : super(key: key);

  @override
  State<ApprovedProvidersScreen> createState() =>
      _ApprovedProvidersScreenState();
}

class _ApprovedProvidersScreenState extends State<ApprovedProvidersScreen> {
  List<dynamic> approved = [];
  List<dynamic> others = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    final url = Uri.parse(approvedProvidersUrl);
    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final all = json.decode(res.body) as List;
        setState(() {
          approved = all.where((p) => p['status'] == 'APPROVED').toList();
          others = all.where((p) => p['status'] != 'APPROVED').toList();
          isLoading = false;
        });
      } else {
        debugPrint('Lỗi: ${res.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() => isLoading = false);
    }
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return "?";
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _resolveAvatarUrl(String? raw) {
    if (raw == null) return '';
    var v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http')) return v;

    // Chuẩn hoá dấu "\" -> "/" nếu DB lỡ lưu kiểu Windows path
    v = v.replaceAll('\\', '/');

    // Lấy server origin từ baseUrl mà không sửa constants:
    // 'http://10.0.2.2:5000/api' -> 'http://10.0.2.2:5000'
    final serverOrigin = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    // Đảm bảo có dấu "/" trước path
    final path = v.startsWith('/') ? v : '/$v';

    return '$serverOrigin$path';
  }


  Widget _providerAvatar(Map<String, dynamic> p) {
    final name = (p['company_name'] ?? '') as String;
    final url = _resolveAvatarUrl(p['avatar']?.toString());
    final initials = _initials(name);

    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.green.shade100,
        child: ClipOval(
          child: Image.network(
            url,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
              initials,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.green.shade100,
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider,
      {bool isApproved = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isApproved ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _providerAvatar(provider),
        title: Text(
          provider['company_name'] ?? 'Không tên',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${provider['email'] ?? "-"}'),
            Text('SĐT: ${provider['phone'] ?? "-"}'),
            if (provider['address'] != null &&
                (provider['address'] as String).trim().isNotEmpty)
              Text('Địa chỉ: ${provider['address']}'),
            if (!isApproved && provider['status'] != null)
              Text(
                'Trạng thái: ${provider['status']}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isApproved)
              IconButton(
                icon: const Icon(Icons.description, color: Colors.green),
                tooltip: 'Xem chi tiết',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderDetailScreen(
                        providerId: provider['_id'],
                        farmerId: widget.farmerId,
                        token: widget.token,
                      ),
                    ),
                  );
                },
              ),
            if (isApproved)
              IconButton(
                icon: const Icon(Icons.send, color: Colors.orange),
                tooltip: 'Gửi yêu cầu',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderDetailScreen(
                        providerId: provider['_id'],
                        farmerId: widget.farmerId,
                        token: widget.token,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          'Các Dịch Vụ Có Sẵn', // <-- tiêu đề
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ProviderCategorySelector(
                  onServiceSelected: (serviceType) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceProvidersMapScreen(
                          token: widget.token,
                          farmerId: widget.farmerId,
                          serviceType: serviceType,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (others.isNotEmpty) ...[
                  const Text(
                    'Nhà cung cấp chưa được duyệt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...others
                      .map((p) => _buildProviderCard(p, isApproved: false)),
                  const SizedBox(height: 24),
                ],
                if (approved.isNotEmpty) ...[
                  const Text(
                    'Nhà cung cấp đã được duyệt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...approved.map((p) => _buildProviderCard(p)),
                ] else if (others.isEmpty) ...[
                  const Center(
                    child: Text('Không có nhà cung cấp nào phù hợp'),
                  )
                ]
              ],
            ),
    );
  }
}

class ProviderCategorySelector extends StatelessWidget {
  final void Function(String serviceType) onServiceSelected;

  ProviderCategorySelector({super.key, required this.onServiceSelected});

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.bug_report, 'label': 'Phun thuốc', 'value': 'Phun thuốc'},
    {'icon': Icons.spa, 'label': 'Bón phân', 'value': 'Bón phân'},
    {'icon': Icons.search, 'label': 'Khảo sát đất', 'value': 'Khảo sát đất'},
    {'icon': Icons.agriculture, 'label': 'Gieo hạt', 'value': 'Gieo hạt'},
    {'icon': Icons.water_drop, 'label': 'Tưới tiêu', 'value': 'Tưới tiêu'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((item) {
            return GestureDetector(
              onTap: () => onServiceSelected(item['value']),
              child: Container(
                width: 72,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      radius: 28,
                      child: Icon(item['icon'], color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['label'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
