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

  String farmerKeyword = '';
  Set<String> selectedStatuses = {};
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context)
                  .viewInsets
                  .add(const EdgeInsets.all(24)),
              child: SingleChildScrollView(
                child: Column(
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
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Tình trạng thanh toán:')),
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
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Loại dịch vụ:')),
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
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      label: const Text('Áp dụng lọc'),
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
    final invoiceStatus = invoice['status'] ?? '---';
    final isPaid = invoiceStatus == 'PAID';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: ListTile(
        title: Text('Dịch vụ: $service',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày: $date'),
            Text('Trạng thái yêu cầu: $status'),
            Text('Tổng tiền: ${invoice['total_amount']} VND'),
            Text('Nông dân: ${farmer?['name'] ?? 'Không rõ'}'),
            Text(
              'Thanh toán: ${isPaid ? 'Đã thanh toán' : 'Chưa thanh toán'}',
              style: TextStyle(
                  color: isPaid ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600),
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
              builder: (_) => InvoiceDetailScreen(invoice: invoice),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Danh sách hóa đơn',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
            ),
    );
  }
}
