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

  // ---------- Helpers ----------
  String _serverOrigin() => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  String _resolveAvatarUrl(String? raw) {
    if (raw == null) return '';
    var v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http')) return v;
    v = v.replaceAll('\\', '/');
    final path = v.startsWith('/') ? v : '/$v';
    return '${_serverOrigin()}$path';
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String _formatVND(num n) {
    final s = n.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i - 1;
      buf.write(s[i]);
      if ((idx) % 3 == 0 && i != s.length - 1) buf.write(',');
    }
    return '${buf.toString()} VND';
  }

  Future<void> fetchInvoices() async {
    setState(() => isLoading = true);

    final res = await http.get(
      Uri.parse('$baseUrl/provider/invoices'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final list = data is List ? data : (data['invoices'] as List? ?? []);
      setState(() {
        invoices = list;
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

  // ---------- Filtering & Stats ----------
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

  int get paidCount =>
      filteredInvoices.where((inv) => inv['status'] == 'PAID').length;

  int get unpaidCount =>
      filteredInvoices.where((inv) => inv['status'] == 'UNPAID').length;

  double get paidTotal =>
      filteredInvoices.where((inv) => inv['status'] == 'PAID').fold<double>(
          0, (sum, inv) => sum + (inv['total_amount'] ?? 0).toDouble());

  double get unpaidTotal =>
      filteredInvoices.where((inv) => inv['status'] == 'UNPAID').fold<double>(
          0, (sum, inv) => sum + (inv['total_amount'] ?? 0).toDouble());

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

    final avatarUrl = _resolveAvatarUrl(farmer?['avatar']?.toString());
    final initials = _initials(farmer?['name']);

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
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: ClipOval(
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.green.shade100,
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.green.shade100,
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
          ),
        ),
        title: Text('Dịch vụ: $service',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày: $date'),
            Text('Trạng thái yêu cầu: $status'),
            Text('Tổng tiền: ${_formatVND((invoice['total_amount'] ?? 0))}'),
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

  Widget _statCard({
    required String title,
    required int count,
    required double total,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text('$count hoá đơn',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(_formatVND(total),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
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
                // Header + nút lọc
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

                // Stats: Paid / Unpaid (count + total)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statCard(
                        title: 'Đã thanh toán',
                        count: paidCount,
                        total: paidTotal,
                        color: Colors.green.shade700,
                        icon: Icons.verified,
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        title: 'Chưa thanh toán',
                        count: unpaidCount,
                        total: unpaidTotal,
                        color: Colors.orange.shade700,
                        icon: Icons.pending_actions,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // List
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
