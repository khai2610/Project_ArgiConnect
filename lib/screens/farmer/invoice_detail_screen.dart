import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final String token;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    required this.token,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Map<String, dynamic> invoice;
  bool isPaying = false;

  @override
  void initState() {
    super.initState();
    invoice = widget.invoice;
  }

  Future<void> _payInvoice() async {
    setState(() => isPaying = true);
    final id = invoice['_id'];
    final url = Uri.parse('$baseUrl/farmer/invoices/$id/pay');

    final res = await http.patch(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    setState(() => isPaying = false);

    if (res.statusCode == 200) {
      final updated = json.decode(res.body);
      setState(() => invoice = updated['invoice']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thanh toán thành công')),
      );
    } else {
      debugPrint('Lỗi thanh toán: ${res.statusCode} - ${res.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thanh toán')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = invoice['service_request_id'];
    final service = request is Map ? request['service_type'] ?? '---' : '---';
    final date = request is Map && request['preferred_date'] != null
        ? DateTime.parse(request['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';
    final requestStatus = request is Map ? request['status'] ?? '---' : '---';
    final invoiceStatus = invoice['status'] ?? '---';
    final total = invoice['total_amount'];
    final note = invoice['note'];
    final isPaid = invoiceStatus == 'PAID';

    final farmer = invoice['farmer_id'];
    final provider = invoice['provider_id'];
    final farmerName = farmer is Map ? farmer['name'] ?? '---' : '---';
    final farmerEmail = farmer is Map ? farmer['email'] ?? '---' : '---';
    final farmerPhone = farmer is Map ? farmer['phone'] ?? '---' : '---';

    final providerCompany =
        provider is Map ? provider['company_name'] ?? '---' : '---';
    final providerEmail = provider is Map ? provider['email'] ?? '---' : '---';
    final providerPhone = provider is Map ? provider['phone'] ?? '---' : '---';

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Chi tiết hóa đơn'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin hóa đơn:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text('Dịch vụ: $service'),
                Text('Ngày yêu cầu: $date'),
                Text('Trạng thái yêu cầu: $requestStatus'),
                const SizedBox(height: 12),
                Text('Tổng tiền: $total VND'),
                Text(
                  'Trạng thái hóa đơn: ${isPaid ? 'Đã thanh toán' : 'Chưa thanh toán'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
                if (note != null && note.toString().isNotEmpty)
                  Text('Ghi chú: $note'),
                const Divider(height: 32),
                const Text(
                  'Thông tin nông dân:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('Họ tên: $farmerName'),
                Text('Email: $farmerEmail'),
                Text('SĐT: $farmerPhone'),
                const Divider(height: 32),
                const Text(
                  'Thông tin nhà cung cấp:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('Tên công ty: $providerCompany'),
                Text('Email: $providerEmail'),
                Text('SĐT: $providerPhone'),
                const SizedBox(height: 24),
                if (!isPaid)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: isPaying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Thanh toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isPaying ? null : _payInvoice,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
