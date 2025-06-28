import 'package:flutter/material.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final farmer = invoice['farmer_id'];
    final request = invoice['service_request_id'];

    final service = request?['service_type'] ?? '---';
    final date = request?['preferred_date'] != null
        ? DateTime.parse(request['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dịch vụ: $service',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ngày yêu cầu: $date'),
            Text('Trạng thái yêu cầu: ${request?['status'] ?? '---'}'),
            const Divider(height: 24),
            Text('Tổng tiền: ${invoice['total_amount']} VND'),
            Text('Trạng thái hóa đơn: ${invoice['status']}'),
            if (invoice['note'] != null &&
                invoice['note'].toString().isNotEmpty)
              Text('Ghi chú: ${invoice['note']}'),
            const Divider(height: 24),
            const Text('Thông tin nông dân:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Họ tên: ${farmer?['name'] ?? '---'}'),
            Text('Email: ${farmer?['email'] ?? '---'}'),
            Text('SĐT: ${farmer?['phone'] ?? '---'}'),
          ],
        ),
      ),
    );
  }
}
