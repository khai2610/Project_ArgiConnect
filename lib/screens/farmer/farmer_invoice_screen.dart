import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'invoice_detail_screen.dart';

class FarmerInvoiceScreen extends StatefulWidget {
  final String token;
  const FarmerInvoiceScreen({super.key, required this.token});

  @override
  State<FarmerInvoiceScreen> createState() => _FarmerInvoiceScreenState();
}

class _FarmerInvoiceScreenState extends State<FarmerInvoiceScreen> {
  List<dynamic> invoices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    setState(() => isLoading = true);
    final res = await http.get(
      Uri.parse('$baseUrl/farmer/invoices'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        invoices = json.decode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải hóa đơn')),
      );
    }
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final provider = invoice['provider_id'];
    final request = invoice['service_request_id'];
    final service = request?['service_type'] ?? '---';
    final date = request?['preferred_date'] != null
        ? DateTime.parse(request['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';
    final status = request?['status'] ?? '---';
    final isPaid = invoice['status'] == 'PAID';

    return Container(
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
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Dịch vụ: $service',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Ngày yêu cầu: $date'),
            Text('Trạng thái yêu cầu: $status'),
            Text('Tổng tiền: ${invoice['total_amount']} VND'),
            Text('Nhà cung cấp: ${provider?['company_name'] ?? '---'}'),
            Text(
              'Thanh toán: ${isPaid ? 'Đã thanh toán' : 'Chưa thanh toán'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isPaid ? Colors.green : Colors.orange,
              ),
            ),
            if (invoice['note'] != null &&
                invoice['note'].toString().isNotEmpty)
              Text('Ghi chú: ${invoice['note']}'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(
                invoice: invoice,
                token: widget.token,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Hóa đơn'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : invoices.isEmpty
              ? const Center(child: Text('Không có hóa đơn nào'))
              : RefreshIndicator(
                  onRefresh: fetchInvoices,
                  child: ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      return _buildInvoiceCard(invoices[index]);
                    },
                  ),
                ),
    );
  }
}
