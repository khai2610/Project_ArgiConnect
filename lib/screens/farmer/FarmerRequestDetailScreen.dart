import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class FarmerRequestDetailScreen extends StatefulWidget {
  final String token;
  final String requestId;

  const FarmerRequestDetailScreen({
    super.key,
    required this.token,
    required this.requestId,
  });

  @override
  State<FarmerRequestDetailScreen> createState() =>
      _FarmerRequestDetailScreenState();
}

class _FarmerRequestDetailScreenState extends State<FarmerRequestDetailScreen> {
  Map<String, dynamic>? request;
  bool isLoading = true;
  bool isPaying = false;
  bool isResending = false;
  bool isRating = false;
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRequest();
  }

  Future<void> fetchRequest() async {
    setState(() => isLoading = true);

    final res = await http.get(
      Uri.parse('$baseUrl/farmer/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final all = json.decode(res.body) as List;
      final found = all.firstWhere(
        (r) => r['_id'] == widget.requestId,
        orElse: () => null,
      );
      setState(() {
        request = found;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải chi tiết yêu cầu')),
      );
    }
  }

  Future<void> _pay() async {
    setState(() => isPaying = true);
    final res = await http.post(
      Uri.parse('$baseUrl/farmer/requests/${widget.requestId}/pay'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    setState(() => isPaying = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công')),
      );
      fetchRequest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thanh toán')),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => isResending = true);
    final res = await http.patch(
      Uri.parse('$baseUrl/farmer/requests/${widget.requestId}/resend'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    setState(() => isResending = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi lại yêu cầu thành công')),
      );
      fetchRequest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi lại yêu cầu')),
      );
    }
  }

  Future<void> _rate() async {
    final rating = int.tryParse(_ratingController.text.trim());
    if (rating == null || rating < 1 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập điểm từ 1 đến 5')),
      );
      return;
    }

    setState(() => isRating = true);
    final res = await http.post(
      Uri.parse('$baseUrl/farmer/requests/${widget.requestId}/rate'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': _commentController.text.trim(),
      }),
    );
    setState(() => isRating = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đánh giá thành công')),
      );
      fetchRequest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi đánh giá')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request?['status'];
    final paymentStatus = request?['payment_status'];
    final rated = request?['rating'] != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Chi tiết yêu cầu'),
      ),
      backgroundColor: Colors.green.shade50,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? const Center(child: Text('Không tìm thấy yêu cầu'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Dịch vụ', request!['service_type']),
                      _buildInfoRow('Cây trồng', request!['crop_type']),
                      _buildInfoRow('Diện tích', '${request!['area_ha']} ha'),
                      _buildInfoRow(
                        'Ngày yêu cầu',
                        request!['preferred_date']?.split('T')[0] ?? '---',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Trạng thái', status),
                      _buildInfoRow('Thanh toán', paymentStatus),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Nhà cung cấp',
                        request!['provider_id']?['company_name'] ?? 'Chưa có',
                      ),
                      const Divider(height: 32),
                      if (status == 'REJECTED')
                        _buildActionButton(
                          icon: Icons.refresh,
                          label: 'Gửi lại yêu cầu',
                          onPressed: isResending ? null : _resend,
                          showLoading: isResending,
                          color: Colors.orange.shade700,
                        ),
                      if (status == 'COMPLETED' && paymentStatus == 'UNPAID')
                        _buildActionButton(
                          icon: Icons.payment,
                          label: 'Thanh toán',
                          onPressed: isPaying ? null : _pay,
                          showLoading: isPaying,
                          color: Colors.green.shade700,
                        ),
                      if (status == 'COMPLETED' &&
                          paymentStatus == 'PAID' &&
                          !rated) ...[
                        const Text('Đánh giá dịch vụ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _ratingController,
                          label: 'Điểm (1–5)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _commentController,
                          label: 'Góp ý (tuỳ chọn)',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.star,
                          label: 'Gửi đánh giá',
                          onPressed: isRating ? null : _rate,
                          showLoading: isRating,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? "---"}'),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool showLoading = false,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: showLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
