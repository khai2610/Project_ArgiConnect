import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'invoice_detail_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final String token;
  const InvoiceScreen({super.key, required this.token});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  List<dynamic> invoices = [];
  bool isLoading = true;

  // Bộ lọc
  String farmerKeyword = '';
  Set<String> selectedStatuses = {}; // PAID, UNPAID
  Set<String> selectedServiceTypes = {};
  List<String> allServiceTypes = [];

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    setState(() => isLoading = true);

    final res = await http.get(
      Uri.parse('$baseUrl/provider/invoices'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        invoices = json.decode(res.body);
        isLoading = false;

        // Lấy tất cả loại dịch vụ duy nhất
        allServiceTypes = invoices
            .map((inv) => inv['service_request_id']?['service_type'])
            .whereType<String>()
            .toSet()
            .toList();
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải danh sách hóa đơn')),
      );
    }
  }

  List<dynamic> get filteredInvoices {
    return invoices.where((inv) {
      final farmer = inv['farmer_id'];
      final request = inv['service_request_id'];

      final matchesFarmer = farmerKeyword.isEmpty ||
          (farmer?['name']?.toLowerCase() ?? '')
              .contains(farmerKeyword.toLowerCase());

      final matchesStatus =
          selectedStatuses.isEmpty || selectedStatuses.contains(inv['status']);

      final matchesService = selectedServiceTypes.isEmpty ||
          selectedServiceTypes.contains(request?['service_type']);

      return matchesFarmer && matchesStatus && matchesService;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context)
                  .viewInsets
                  .add(const EdgeInsets.all(16)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Lọc hóa đơn',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Tên nông dân'),
                      onChanged: (value) =>
                          setModalState(() => farmerKeyword = value),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tình trạng thanh toán:'),
                    CheckboxListTile(
                      title: const Text('Đã thanh toán'),
                      value: selectedStatuses.contains('PAID'),
                      onChanged: (val) => setModalState(() {
                        val!
                            ? selectedStatuses.add('PAID')
                            : selectedStatuses.remove('PAID');
                      }),
                    ),
                    CheckboxListTile(
                      title: const Text('Chưa thanh toán'),
                      value: selectedStatuses.contains('UNPAID'),
                      onChanged: (val) => setModalState(() {
                        val!
                            ? selectedStatuses.add('UNPAID')
                            : selectedStatuses.remove('UNPAID');
                      }),
                    ),
                    const Divider(),
                    const Text('Loại dịch vụ:'),
                    ...allServiceTypes.map((type) => CheckboxListTile(
                          title: Text(type),
                          value: selectedServiceTypes.contains(type),
                          onChanged: (val) => setModalState(() {
                            val!
                                ? selectedServiceTypes.add(type)
                                : selectedServiceTypes.remove(type);
                          }),
                        )),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {}); // cập nhật lọc
                      },
                      child: const Text('Áp dụng lọc'),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Danh sách hóa đơn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.filter_alt),
                label: const Text('Lọc'),
                onPressed: _showFilterSheet,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchInvoices,
            child: filteredInvoices.isEmpty
                ? const Center(child: Text('Không có hóa đơn phù hợp'))
                : ListView.builder(
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      return _buildInvoiceCard(filteredInvoices[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
