import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'FarmerRequestDetailScreen.dart'; // điều chỉnh path nếu cần

class MyRequestsScreen extends StatefulWidget {
  final String token;
  const MyRequestsScreen({super.key, required this.token});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;
  // ALL | COMPLETED | PENDING | REJECTED | ACCEPTED
  String statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ========== Helpers ==========
  IconData _iconForService(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('phun') || t.contains('thuốc')) return Icons.bug_report;
    if (t.contains('bón') || t.contains('phân')) return Icons.spa;
    if (t.contains('khảo') || t.contains('đất')) return Icons.search;
    if (t.contains('gieo') || t.contains('hạt')) return Icons.agriculture;
    if (t.contains('tưới') || t.contains('nước') || t.contains('tiêu')) {
      return Icons.water_drop;
    }
    return Icons.miscellaneous_services;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'ACCEPTED':
        return Colors.blue.shade700;
      case 'PENDING':
        return Colors.orange.shade700;
      case 'REJECTED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // ========== API ==========
  Future<void> fetchRequests() async {
    setState(() => isLoading = true);

    final res = await http.get(
      Uri.parse('$baseUrl/farmer/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        requests = json.decode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải yêu cầu')),
      );
    }
  }

  Future<void> _payRequest(String requestId) async {
    final url = Uri.parse('$baseUrl/farmer/requests/$requestId/pay');

    final res = await http.post(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công')),
      );
      fetchRequests();
    } else {
      debugPrint('Lỗi thanh toán: ${res.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi thanh toán')),
      );
    }
  }

  Future<void> _resendRequest(String requestId) async {
    final url = Uri.parse('$baseUrl/farmer/requests/$requestId/resend');

    final res = await http.patch(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi lại yêu cầu thành công')),
      );
      fetchRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi lại yêu cầu')),
      );
    }
  }

  void _confirmAndPay(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: const Text(
            'Bạn có chắc chắn muốn thanh toán cho yêu cầu này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _payRequest(requestId);
    }
  }

  // ========== UI ==========
  Widget _buildRequestCard(Map<String, dynamic> req) {
    final provider = req['provider_id'];
    final area = (req['area_ha'] ?? 0.0).toString();
    final date = req['preferred_date'] != null
        ? DateTime.parse(req['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : 'Chưa chọn';
    final status = (req['status'] ?? '').toString();
    final requestId = req['_id'];
    final rating = req['rating'];
    final comment = req['comment'];
    final serviceType = (req['service_type'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FarmerRequestDetailScreen(
              token: widget.token,
              requestId: requestId,
            ),
          ),
        ).then((_) => fetchRequests());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON loại dịch vụ
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.shade50,
              child: Icon(
                _iconForService(serviceType),
                color: Colors.green.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề + chip trạng thái
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          serviceType.isEmpty ? 'Dịch vụ' : serviceType,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text('Diện tích: $area ha'),
                  Text('Ngày: $date'),
                  Text(
                      'Nhà cung cấp: ${provider != null ? provider['company_name'] : 'Tự do'}'),

                  const SizedBox(height: 8),

                  if (status == 'REJECTED')
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _resendRequest(requestId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Gửi lại yêu cầu'),
                      ),
                    ),

                  if (rating != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Đánh giá: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Icon(Icons.star, color: Colors.amber.shade600),
                        Text('$rating / 5'),
                      ],
                    ),
                    if (comment != null && comment.toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Nhận xét: $comment'),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = statusFilter == 'ALL'
        ? requests
        : requests.where((r) => r['status'] == statusFilter).toList();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Yêu cầu của tôi',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined),
                      const SizedBox(width: 8),
                      const Text('Lọc trạng thái:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: statusFilter,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                          DropdownMenuItem(
                              value: 'COMPLETED', child: Text('Hoàn thành')),
                          DropdownMenuItem(
                              value: 'PENDING', child: Text('Chờ xử lý')),
                          DropdownMenuItem(
                              value: 'ACCEPTED', child: Text('Đã chấp nhận')),
                          DropdownMenuItem(
                              value: 'REJECTED', child: Text('Từ chối')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => statusFilter = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchRequests,
                    child: filteredRequests.isEmpty
                        ? const Center(
                            child: Text('Không có yêu cầu nào phù hợp'))
                        : ListView.builder(
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) =>
                                _buildRequestCard(filteredRequests[index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
