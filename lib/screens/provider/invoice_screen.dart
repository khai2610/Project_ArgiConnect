import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class InvoiceScreen extends StatefulWidget {
  final String token;
  const InvoiceScreen({super.key, required this.token});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  List<dynamic> invoices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    final res = await http.get(
      Uri.parse('$baseUrl/provider/invoices'),
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
        const SnackBar(content: Text('Không thể tải danh sách hóa đơn')),
      );
    }
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final farmer = invoice['farmer_id'];
    final request = invoice['service_request_id'];

    final service = request?['service_type'] ?? '---';
    final date = request?['preferred_date'] != null
        ? DateTime.parse(request['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';
    final status = request?['status'] ?? '---';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text('Dịch vụ: $service'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày: $date'),
            Text('Trạng thái yêu cầu: $status'),
            Text('Tổng tiền: ${invoice['total_amount']} VND'),
            Text('Nông dân: ${farmer?['name'] ?? 'Không rõ'}'),
            if (invoice['note'] != null &&
                invoice['note'].toString().isNotEmpty)
              Text('Ghi chú: ${invoice['note']}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (invoices.isEmpty) {
      return const Center(child: Text('Chưa có hóa đơn nào'));
    }

    return RefreshIndicator(
      onRefresh: fetchInvoices,
      child: ListView.builder(
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          return _buildInvoiceCard(invoices[index]);
        },
      ),
    );
  }
}
