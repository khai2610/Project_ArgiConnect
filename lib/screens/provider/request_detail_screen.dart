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

  // ---------------- Helpers: avatar + URL ----------------
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

  Widget _fallbackInitials(String? name) {
    return Container(
      color: Colors.green.shade100,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  // ---------------- Data fetch ----------------
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

      // Gợi ý tổng tiền khi đã có price*area (sau COMPLETE)
      if (found != null && found['status'] == 'COMPLETED') {
        final paymentStatus = found['payment_status'];
        if (paymentStatus != null && paymentStatus != '') {
          // hóa đơn đã/đang tồn tại, không cần set tạm
        } else {
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
                _invoiceAmountController.text =
                    (price * area).toStringAsFixed(0);
              }
            }
          } catch (e) {
            debugPrint('Price hint error: $e');
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

  // ---------------- Actions ----------------
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

  // ---------------- UI pieces ----------------
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? "---"}'),
    );
  }

  Widget _buildColoredStatus(String label, String? value, [Color? override]) {
    final color = override ??
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool showLoading = false,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: showLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.green.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _card(Widget child) {
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
      child: child,
    );
  }

  // Header card có avatar nông dân bên phải, chống overflow
  Widget _headerCard(Map<String, dynamic> req) {
    final farmer = req['farmer_id'] as Map<String, dynamic>?;
    final avatarUrl = _resolveAvatarUrl(farmer?['avatar']?.toString());

    return _card(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text info - Expanded để không tràn Row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Dịch vụ', req['service_type']),
                _buildInfoRow('Cây trồng', req['crop_type']),
                _buildInfoRow('Diện tích', '${req['area_ha']} ha'),
                _buildInfoRow('Ngày mong muốn',
                    req['preferred_date']?.split('T')[0] ?? '---'),
                _buildColoredStatus('Trạng thái', req['status']),
                _buildColoredStatus('Thanh toán', req['payment_status']),
                const SizedBox(height: 8),
                if (farmer != null) ...[
                  Text('Nông dân: ${farmer['name'] ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if ((farmer['phone'] ?? '').toString().isNotEmpty)
                    Text('SĐT: ${farmer['phone']}'),
                  if ((farmer['email'] ?? '').toString().isNotEmpty)
                    Text('Email: ${farmer['email']}'),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar fixed size + cover
          SizedBox(
            width: 88,
            height: 88,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(44),
              child: (avatarUrl.isNotEmpty)
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _fallbackInitials(farmer?['name']),
                    )
                  : _fallbackInitials(farmer?['name']),
            ),
          ),
        ],
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
                        _headerCard(request!),
                        const SizedBox(height: 16),

                        // PENDING: accept / reject
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
                            color: Colors.red.shade600,
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

                        // ACCEPTED: complete form
                        if (status == 'ACCEPTED') ...[
                          _card(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hoàn thành yêu cầu',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 12),
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
                                          'Authorization':
                                              'Bearer ${widget.token}',
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'description': description,
                                          'attachments': attachment.isNotEmpty
                                              ? [attachment]
                                              : [],
                                        }),
                                      );

                                      if (res.statusCode == 200) {
                                        final data = jsonDecode(res.body);
                                        final updated = data['request'];
                                        if (updated != null &&
                                            updated['total_amount'] != null) {
                                          _invoiceAmountController.text =
                                              updated['total_amount']
                                                  .toString();
                                        }

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  '✅ Yêu cầu đã hoàn thành')),
                                        );
                                        await fetchRequestDetail();
                                      } else {
                                        final body = res.body;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi ${res.statusCode}: ${jsonDecode(body)['message'] ?? 'Không thể hoàn thành yêu cầu'}',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('complete error: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Đã xảy ra lỗi không mong muốn')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // COMPLETED: result + invoice
                        if (status == 'COMPLETED') ...[
                          _card(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kết quả xử lý',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(request!['result']?['description'] ??
                                    'Không có mô tả'),
                                const SizedBox(height: 8),
                                if ((request!['result']?['attachments']
                                            as List?)
                                        ?.isNotEmpty ??
                                    false)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Tệp đính kèm:'),
                                      ...(request!['result']['attachments']
                                              as List)
                                          .map((url) => Text('• $url')),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (paymentStatus == 'PAID' ||
                              paymentStatus == 'UNPAID')
                            _card(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Hóa đơn',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Tổng tiền: $invoiceAmount VND',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  _buildColoredStatus(
                                    'Trạng thái hóa đơn',
                                    paymentStatus,
                                    paymentStatus == 'PAID'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                            )
                          else
                            _card(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Lập hóa đơn',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Tổng tiền tạm tính: $invoiceAmount VND',
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _invoiceNoteController,
                                    label: 'Ghi chú (nếu có)',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionButton(
                                    icon: Icons.receipt,
                                    label: 'Lập hóa đơn',
                                    onPressed: isCreatingInvoice
                                        ? null
                                        : _createInvoice,
                                    showLoading: isCreatingInvoice,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
