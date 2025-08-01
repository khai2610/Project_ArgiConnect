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
  String selectedStatus = 'Tất cả';
  bool sortDescending = true;

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
    final createdAt = DateTime.tryParse(invoice['createdAt'] ?? '');
    final paidAt = invoice['paidAt'] != null
        ? DateTime.tryParse(invoice['paidAt'])?.toLocal()
        : null;

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
            Text(
                'Ngày lập hóa đơn: ${createdAt != null ? createdAt.toString().split(' ')[0] : '---'}'),
            if (paidAt != null)
              Text('Ngày thanh toán: ${paidAt.toString().split(' ')[0]}'),
            if (invoice['note'] != null &&
                invoice['note'].toString().isNotEmpty)
              Text('Ghi chú: ${invoice['note']}'),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(
                invoice: invoice,
                token: widget.token,
              ),
            ),
          );

          if (result == true) {
            fetchInvoices();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvoices = invoices.where((inv) {
      if (selectedStatus == 'Đã thanh toán') return inv['status'] == 'PAID';
      if (selectedStatus == 'Chưa thanh toán') return inv['status'] != 'PAID';
      return true;
    }).toList();

    filteredInvoices.sort((a, b) {
      final timeA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
      final timeB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
      return sortDescending ? timeB.compareTo(timeA) : timeA.compareTo(timeB);
    });

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Hóa đơn'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          items: ['Tất cả', 'Đã thanh toán', 'Chưa thanh toán']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedStatus = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          sortDescending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                        ),
                        onPressed: () {
                          setState(() => sortDescending = !sortDescending);
                        },
                        tooltip: 'Sắp xếp theo thời gian',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: fetchInvoices,
                    child: filteredInvoices.isEmpty
                        ? const Center(child: Text('Không có hóa đơn nào'))
                        : ListView.builder(
                            itemCount: filteredInvoices.length,
                            itemBuilder: (context, index) {
                              return _buildInvoiceCard(filteredInvoices[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
