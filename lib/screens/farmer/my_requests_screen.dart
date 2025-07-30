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
  String paymentFilter = 'ALL'; // ALL | PAID | UNPAID

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

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

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final provider = req['provider_id'];
    final crop = req['crop_type'] ?? 'Không rõ';
    final service = req['service_type'] ?? 'Không rõ';
    final area = req['area_ha'] ?? 0.0;
    final date = req['preferred_date'] != null
        ? DateTime.parse(req['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : 'Chưa chọn';
    final status = req['status'];
    final payment = req['payment_status'];
    final requestId = req['_id'];

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
        ).then((_) => fetchRequests()); // reload khi quay lại
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$crop - $service',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Diện tích: $area ha'),
            Text('Ngày yêu cầu: $date'),
            Text(
                'Nhà cung cấp: ${provider != null ? provider['company_name'] : 'Tự do'}'),
            Text('Trạng thái: $status'),
            Text('Thanh toán: $payment'),
            const SizedBox(height: 8),
            if (payment == 'UNPAID' && status == 'COMPLETED')
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _confirmAndPay(requestId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Thanh toán'),
                ),
              ),
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
          ],
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = paymentFilter == 'ALL'
        ? requests
        : requests.where((r) => r['payment_status'] == paymentFilter).toList();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Yêu cầu của tôi'),
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
                      const Text('Lọc thanh toán:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: paymentFilter,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                          DropdownMenuItem(
                              value: 'PAID', child: Text('Đã thanh toán')),
                          DropdownMenuItem(
                              value: 'UNPAID', child: Text('Chưa thanh toán')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              paymentFilter = value;
                            });
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
