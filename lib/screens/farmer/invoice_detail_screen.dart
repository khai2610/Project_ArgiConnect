import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
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

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen>
    with WidgetsBindingObserver {
  late Map<String, dynamic> invoice;
  bool isPaying = false;

  @override
  void initState() {
    super.initState();
    invoice = widget.invoice;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchInvoice();
    }
  }

  Future<void> _fetchInvoice() async {
    final id = widget.invoice['_id'];
    final url = Uri.parse('$baseUrl/farmer/invoices/$id');

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          invoice = data['invoice'];
        });
      } else {
        debugPrint('❌ Không thể tải lại hóa đơn: ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ Lỗi kết nối khi tải hóa đơn: $e');
    }
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
      Navigator.pop(context, true);
    } else {
      debugPrint('Lỗi thanh toán: ${res.statusCode} - ${res.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thanh toán')),
      );
    }
  }

  Future<void> _payWithMomo() async {
    final id = invoice['_id'];
    final url = Uri.parse('$baseUrl/payment/create');

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({'invoiceId': id}),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['payUrl'] != null) {
        final payUrl = data['payUrl'] as String;
        if (context.mounted) {
          await launchUrl(Uri.parse(payUrl),
              mode: LaunchMode.externalApplication);
        }
      } else {
        debugPrint('⚠️ MoMo không trả về payUrl: ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo thanh toán MoMo')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi kết nối MoMo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi gọi MoMo')),
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
      body: Column(
        children: [
          Expanded(
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    const Text('Thông tin nông dân:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Họ tên: $farmerName'),
                    Text('Email: $farmerEmail'),
                    Text('SĐT: $farmerPhone'),
                    const Divider(height: 32),
                    const Text('Thông tin nhà cung cấp:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Tên công ty: $providerCompany'),
                    Text('Email: $providerEmail'),
                    Text('SĐT: $providerPhone'),
                  ],
                ),
              ),
            ),
          ),
          if (!isPaid)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.wallet),
                      label: const Text('Thanh toán Momo (Giả lập)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _payWithMomo,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payments),
                      label: isPaying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Thanh toán trực tiếp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isPaying ? null : _payInvoice,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
