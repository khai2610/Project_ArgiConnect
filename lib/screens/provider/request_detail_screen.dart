import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  final String token;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    required this.token,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? request;
  bool isLoading = true;
  bool isCreatingInvoice = false;
  bool _invoiceCreated = false;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();
  final TextEditingController _invoiceAmountController =
      TextEditingController();
  final TextEditingController _invoiceNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRequestDetail();
  }

  Future<void> fetchRequestDetail() async {
    setState(() => isLoading = true);
    final res = await http.get(
      Uri.parse('$baseUrl/provider/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final all = jsonDecode(res.body) as List;
      final found = all.firstWhere((r) => r['_id'] == widget.requestId,
          orElse: () => null);

      if (found != null) {
        if (found['status'] == 'COMPLETED') {
          final paymentStatus = found['payment_status'];
          _invoiceCreated =
              paymentStatus == 'PAID' || paymentStatus == 'UNPAID';

          final provider = found['provider_id'];
          final area = (found['area_ha'] ?? 0.0).toDouble();
          final service = found['service_type'];

          try {
            if (provider != null && provider['services'] is List) {
              final services = provider['services'] as List;
              final matched = services.firstWhere(
                (s) => s is Map && s['name'] == service,
                orElse: () => null,
              );
              if (matched != null && matched['price'] != null) {
                final price = (matched['price'] as num).toDouble();
                final total = (price * area).toStringAsFixed(0);
                _invoiceAmountController.text = total;
              }
            }
          } catch (e) {
            debugPrint('❌ Lỗi khi xử lý services: $e');
          }
        }
      }

      setState(() {
        request = found;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được chi tiết yêu cầu')),
      );
    }
  }

  Future<void> _createInvoice() async {
    setState(() => isCreatingInvoice = true);
    final res = await http.post(
      Uri.parse('$baseUrl/provider/invoices'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'request_id': widget.requestId,
        'note': _invoiceNoteController.text.trim(),
      }),
    );
    setState(() => isCreatingInvoice = false);

    if (res.statusCode == 201) {
      final body = jsonDecode(res.body);
      final invoice = body['invoice'];
      final amount = invoice['total_amount'];
      _invoiceAmountController.text = amount.toString();

      setState(() => _invoiceCreated = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lập hóa đơn thành công (${amount} VND)')),
      );

      fetchRequestDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi lập hóa đơn')),
      );
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? "---"}'),
    );
  }

  Widget _buildColoredStatus(String label, String? value,
      [Color? colorOverride]) {
    final color = colorOverride ??
        (value == 'PAID'
            ? Colors.green
            : value == 'UNPAID'
                ? Colors.orange
                : Colors.blueGrey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: $value',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool showLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: showLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCardSection(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = request?['status'];
    final paymentStatus = request?['payment_status'];

    final invoice = request?['invoice'];
    final invoiceAmount = invoice != null
        ? invoice['total_amount']?.toString() ?? '---'
        : _invoiceAmountController.text;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Chi tiết yêu cầu'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? const Center(child: Text('Không tìm thấy yêu cầu'))
              : RefreshIndicator(
                  onRefresh: fetchRequestDetail,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardSection([
                          _buildInfoRow('Dịch vụ', request!['service_type']),
                          _buildInfoRow('Cây trồng', request!['crop_type']),
                          _buildInfoRow(
                              'Diện tích', '${request!['area_ha']} ha'),
                          _buildInfoRow(
                              'Ngày mong muốn',
                              request!['preferred_date']?.split('T')[0] ??
                                  '---'),
                          _buildColoredStatus('Trạng thái', status),
                          _buildColoredStatus('Thanh toán', paymentStatus),
                        ]),
                        const SizedBox(height: 16),

                        // ✅ Nếu trạng thái là PENDING
                        if (status == 'PENDING') ...[
                          _buildActionButton(
                            icon: Icons.check,
                            label: 'Chấp nhận yêu cầu',
                            onPressed: () async {
                              final res = await http.patch(
                                Uri.parse(
                                    '$baseUrl/provider/requests/${widget.requestId}/accept'),
                                headers: {
                                  'Authorization': 'Bearer ${widget.token}'
                                },
                              );
                              if (res.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Đã chấp nhận yêu cầu')),
                                );
                                fetchRequestDetail();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Không thể chấp nhận yêu cầu')),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            icon: Icons.close,
                            label: 'Từ chối yêu cầu',
                            onPressed: () async {
                              final res = await http.patch(
                                Uri.parse(
                                    '$baseUrl/provider/requests/${widget.requestId}/reject'),
                                headers: {
                                  'Authorization': 'Bearer ${widget.token}'
                                },
                              );
                              if (res.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Đã từ chối yêu cầu')),
                                );
                                Navigator.pop(context, true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Không thể từ chối yêu cầu')),
                                );
                              }
                            },
                          ),
                        ],

                        if (status == 'ACCEPTED') ...[
                          _buildSectionTitle('Hoàn thành yêu cầu'),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Mô tả kết quả',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _attachmentController,
                            label: 'Link đính kèm (nếu có)',
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.check_circle_outline,
                            label: 'Xác nhận hoàn thành',
                            onPressed: () async {
                              final description =
                                  _descriptionController.text.trim();
                              final attachment =
                                  _attachmentController.text.trim();

                              try {
                                final res = await http.patch(
                                  Uri.parse(
                                      '$baseUrl/provider/requests/${widget.requestId}/complete'),
                                  headers: {
                                    'Authorization': 'Bearer ${widget.token}',
                                    'Content-Type': 'application/json',
                                  },
                                  body: jsonEncode({
                                    'description': description,
                                    'attachments': attachment.isNotEmpty
                                        ? [attachment]
                                        : [],
                                  }),
                                );

                                final code = res.statusCode;
                                final body = res.body;

                                if (code == 200) {
                                  final data = jsonDecode(body);
                                  final updated = data['request'];
                                  if (updated != null &&
                                      updated['total_amount'] != null) {
                                    _invoiceAmountController.text =
                                        updated['total_amount']
                                            .toString(); // ✅ gán vào controller
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('✅ Yêu cầu đã hoàn thành')),
                                  );

                                  await fetchRequestDetail(); // cập nhật lại giao diện
                                } else {
                                  debugPrint(
                                      '❌ Complete failed [$code]: $body');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Lỗi $code: ${jsonDecode(body)['message'] ?? 'Không thể hoàn thành yêu cầu'}')),
                                  );
                                }
                              } catch (e) {
                                debugPrint('❌ Exception during complete: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Đã xảy ra lỗi không mong muốn')),
                                );
                              }
                            },
                          ),
                        ],


                        if (status == 'COMPLETED') ...[
                          _buildSectionTitle('Kết quả xử lý'),
                          Text(request!['result']?['description'] ??
                              'Không có mô tả'),
                          const SizedBox(height: 8),
                          if ((request!['result']?['attachments'] as List?)
                                  ?.isNotEmpty ??
                              false)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tệp đính kèm:'),
                                ...(request!['result']['attachments'] as List)
                                    .map((url) => Text('• $url')),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (paymentStatus == 'PAID' ||
                              paymentStatus == 'UNPAID') ...[
                            _buildSectionTitle('Hóa đơn'),
                            Text(
                              'Tổng tiền: $invoiceAmount VND',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildColoredStatus(
                              'Trạng thái hóa đơn',
                              paymentStatus,
                              paymentStatus == 'PAID'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ] else ...[
                            _buildSectionTitle('Lập hóa đơn'),
                            Text(
                              'Tổng tiền tạm tính: $invoiceAmount VND',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _invoiceNoteController,
                              label: 'Ghi chú (nếu có)',
                            ),
                            const SizedBox(height: 12),
                            _buildActionButton(
                              icon: Icons.receipt,
                              label: 'Lập hóa đơn',
                              onPressed:
                                  isCreatingInvoice ? null : _createInvoice,
                              showLoading: isCreatingInvoice,
                            ),
                          ]
                        ]
                      ],
                    ),
                  ),
                ),
    );
  }
}
