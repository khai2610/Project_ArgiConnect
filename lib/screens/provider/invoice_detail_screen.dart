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
    final status = request?['status'] ?? '---';
    final invoiceStatus = invoice['status'] ?? '---';
    final total = invoice['total_amount'];
    final note = invoice['note'];

    final isPaid = invoiceStatus == 'PAID';

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
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin hóa đơn:',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Dịch vụ: $service'),
                Text('Ngày yêu cầu: $date'),
                Text('Trạng thái yêu cầu: $status'),
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
                Text('Họ tên: ${farmer?['name'] ?? '---'}'),
                Text('Email: ${farmer?['email'] ?? '---'}'),
                Text('SĐT: ${farmer?['phone'] ?? '---'}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
