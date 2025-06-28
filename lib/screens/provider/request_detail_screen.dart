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
      _descriptionController.clear();
      _attachmentController.clear();
      fetchRequestDetail();
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
      _invoiceAmountController.clear();
      _invoiceNoteController.clear();
      fetchRequestDetail();
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
      appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? const Center(child: Text('Không tìm thấy yêu cầu'))
              : RefreshIndicator(
                  onRefresh: fetchRequestDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dịch vụ: ${request!['service_type'] ?? '---'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Cây trồng: ${request!['crop_type'] ?? '---'}'),
                        Text('Diện tích: ${request!['area_ha'] ?? 0} ha'),
                        Text(
                            'Ngày mong muốn: ${request!['preferred_date']?.split('T')[0] ?? '---'}'),
                        Text('Trạng thái: $status'),
                        Text('Thanh toán: $paymentStatus'),
                        const Divider(height: 32),
                        if (status == 'PENDING') ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Chấp nhận yêu cầu'),
                            onPressed: _acceptRequest,
                          ),
                        ],
                        if (status == 'ACCEPTED') ...[
                          const Text('Hoàn thành yêu cầu:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Mô tả kết quả',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _attachmentController,
                            decoration: const InputDecoration(
                              labelText: 'Link đính kèm (nếu có)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: isCompleting ? null : _completeRequest,
                            child: isCompleting
                                ? const CircularProgressIndicator()
                                : const Text('Xác nhận hoàn thành'),
                          ),
                        ],
                        if (status == 'COMPLETED') ...[
                          const Text('Kết quả xử lý:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(request!['result']?['description'] ??
                              'Không có mô tả'),
                          const SizedBox(height: 12),
                          if ((request!['result']?['attachments'] as List?)
                                  ?.isNotEmpty ??
                              false)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tệp đính kèm:'),
                                const SizedBox(height: 6),
                                ...(request!['result']['attachments'] as List)
                                    .map((url) => Text('• $url')),
                              ],
                            ),
                          const Divider(height: 24),
                          if (paymentStatus == 'UNPAID') ...[
                            const Text('Hóa đơn: Chưa thanh toán',
                                style: TextStyle(color: Colors.orange)),
                          ] else if (paymentStatus == 'PAID') ...[
                            const Text('Hóa đơn: Đã thanh toán',
                                style: TextStyle(color: Colors.green)),
                          ] else ...[
                            const Text('Lập hóa đơn:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _invoiceAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Tổng tiền (VND)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _invoiceNoteController,
                              decoration: const InputDecoration(
                                labelText: 'Ghi chú (nếu có)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed:
                                  isCreatingInvoice ? null : _createInvoice,
                              child: isCreatingInvoice
                                  ? const CircularProgressIndicator()
                                  : const Text('Lập hóa đơn'),
                            ),
                          ]
                        ],
                        const Divider(height: 32),
                        const Text('Thông tin nông dân:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                            'Họ tên: ${request!['farmer_id']?['name'] ?? '---'}'),
                        Text(
                            'Email: ${request!['farmer_id']?['email'] ?? '---'}'),
                        Text(
                            'SĐT: ${request!['farmer_id']?['phone'] ?? '---'}'),
                      ],
                    ),
                  ),
                ),
    );
  }
}
