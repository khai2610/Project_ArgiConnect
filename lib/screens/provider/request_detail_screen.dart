import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  final String token;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    required this.token,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? request;
  bool isLoading = true;
  bool isCompleting = false;
  bool isCreatingInvoice = false;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();
  final TextEditingController _invoiceAmountController =TextEditingController();
  final TextEditingController _invoiceNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRequestDetail();
  }

  Future<void> fetchRequestDetail() async {
    setState(() => isLoading = true);
    final res = await http.get(
      Uri.parse('$baseUrl/provider/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final all = jsonDecode(res.body) as List;
      final found = all.firstWhere((r) => r['_id'] == widget.requestId,
          orElse: () => null);
      setState(() {
        request = found;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được chi tiết yêu cầu')),
      );
    }
  }

  Future<void> _acceptRequest() async {
    final res = await http.patch(
      Uri.parse('$baseUrl/provider/requests/${widget.requestId}/accept'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận yêu cầu')),
      );
      fetchRequestDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chấp nhận yêu cầu')),
      );
    }
  }

  Future<void> _completeRequest() async {
    setState(() => isCompleting = true);

    final res = await http.patch(
      Uri.parse('$baseUrl/provider/requests/${widget.requestId}/complete'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'description': _descriptionController.text,
        'attachments': _attachmentController.text.isNotEmpty
            ? [_attachmentController.text]
            : [],
      }),
    );

    setState(() => isCompleting = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yêu cầu đã hoàn thành')),
      );
      Navigator.pop(context, true); // ✅ báo về RequestListScreen để reload
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể hoàn thành yêu cầu')),
      );
    }
  }

  Future<void> _createInvoice() async {
    final amount = double.tryParse(_invoiceAmountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    setState(() => isCreatingInvoice = true);

    final res = await http.post(
      Uri.parse('$baseUrl/provider/invoices'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': widget.requestId,
        'total_amount': amount,
        'note': _invoiceNoteController.text.trim(),
      }),
    );

    setState(() => isCreatingInvoice = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lập hóa đơn thành công')),
      );
      Navigator.pop(
          context, true); // ✅ reload RequestListScreen sau khi lập hóa đơn
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        
        const SnackBar(content: Text('Lỗi khi lập hóa đơn')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request?['status'];
    final paymentStatus = request?['payment_status'];

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Chi tiết yêu cầu'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? const Center(child: Text('Không tìm thấy yêu cầu'))
              : RefreshIndicator(
                  onRefresh: fetchRequestDetail,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardSection([
                          _buildInfoRow('Dịch vụ', request!['service_type']),
                          _buildInfoRow('Cây trồng', request!['crop_type']),
                          _buildInfoRow(
                              'Diện tích', '${request!['area_ha'] ?? 0} ha'),
                          _buildInfoRow(
                              'Ngày mong muốn',
                              request!['preferred_date']?.split('T')[0] ??
                                  '---'),
                          _buildColoredStatus('Trạng thái', status),
                          _buildColoredStatus('Thanh toán', paymentStatus),
                        ]),
                        const SizedBox(height: 16),
                        if (status == 'PENDING') ...[
                          _buildActionButton(
                            icon: Icons.check,
                            label: 'Chấp nhận yêu cầu',
                            onPressed: _acceptRequest,
                          ),
                        ],
                        if (status == 'ACCEPTED') ...[
                          _buildSectionTitle('Hoàn thành yêu cầu'),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Mô tả kết quả',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _attachmentController,
                            label: 'Link đính kèm (nếu có)',
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.check_circle_outline,
                            label: 'Xác nhận hoàn thành',
                            onPressed: isCompleting ? null : _completeRequest,
                            showLoading: isCompleting,
                          ),
                        ],
                        if (status == 'COMPLETED') ...[
                          _buildSectionTitle('Kết quả xử lý'),
                          Text(request!['result']?['description'] ??
                              'Không có mô tả'),
                          const SizedBox(height: 8),
                          if ((request!['result']?['attachments'] as List?)
                                  ?.isNotEmpty ??
                              false)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                const Text('Tệp đính kèm:'),
                                const SizedBox(height: 4),
                                ...(request!['result']['attachments'] as List)
                                    .map((url) => Text('• $url')),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (paymentStatus == 'UNPAID') ...[
                            _buildColoredStatus(
                                'Hóa đơn', 'Chưa thanh toán', Colors.orange),
                          ] else if (paymentStatus == 'PAID') ...[
                            _buildColoredStatus(
                                'Hóa đơn', 'Đã thanh toán', Colors.green),
                          ] else ...[
                            _buildSectionTitle('Lập hóa đơn'),
                            _buildTextField(
                              controller: _invoiceAmountController,
                              label: 'Tổng tiền (VND)',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _invoiceNoteController,
                              label: 'Ghi chú (nếu có)',
                            ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.receipt,
                              label: 'Lập hóa đơn',
                              onPressed:
                                  isCreatingInvoice ? null : _createInvoice,
                              showLoading: isCreatingInvoice,
                            ),
                          ]
                        ],
                        const SizedBox(height: 20),
                        _buildSectionTitle('Thông tin nông dân'),
                        _buildInfoRow(
                            'Họ tên', request!['farmer_id']?['name'] ?? '---'),
                        _buildInfoRow(
                            'Email', request!['farmer_id']?['email'] ?? '---'),
                        _buildInfoRow(
                            'SĐT', request!['farmer_id']?['phone'] ?? '---'),
                      ],
                    ),
                  ),
                ),
    );
  }

// === WIDGET HELPERS ===

  Widget _buildCardSection(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? "---"}'),
    );
  }

  Widget _buildColoredStatus(String label, String? value,
      [Color? colorOverride]) {
    final color = colorOverride ??
        (value == 'PAID'
            ? Colors.green
            : value == 'UNPAID'
                ? Colors.orange
                : Colors.blueGrey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: $value',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
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
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: showLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

}
