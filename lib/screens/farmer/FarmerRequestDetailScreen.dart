import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'create_request_screen.dart'; // chỉnh lại nếu path khác

class FarmerRequestDetailScreen extends StatefulWidget {
  final String token;
  final String requestId;

  const FarmerRequestDetailScreen({
    super.key,
    required this.token,
    required this.requestId,
  });

  @override
  State<FarmerRequestDetailScreen> createState() =>
      _FarmerRequestDetailScreenState();
}

class _FarmerRequestDetailScreenState extends State<FarmerRequestDetailScreen> {
  Map<String, dynamic>? request;
  Map<String, dynamic>? _providerFull; // 👈 lưu provider đầy đủ (có avatar)
  bool isLoading = true;
  bool isPaying = false;
  bool isResending = false;
  bool isRating = false;

  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRequest();
  }

  // ========= Helpers (avatar) =========
  String _serverOrigin() => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  String? _resolveAvatarUrl(String? raw) {
    if (raw == null) return null;
    var v = raw.trim();
    if (v.isEmpty) return null;
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

  // ========= API =========
  Future<void> fetchRequest() async {
    setState(() {
      isLoading = true;
      _providerFull = null; // reset
    });

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/farmer/requests'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final all = json.decode(res.body) as List;
        final found = all.firstWhere(
          (r) => r['_id'] == widget.requestId,
          orElse: () => null,
        );

        // Thử lấy info provider đầy đủ nếu thiếu avatar trong payload list requests
        if (found != null) {
          final prov = found['provider_id'];
          final provId =
              prov is Map ? prov['_id'] : (prov is String ? prov : null);

          if (provId != null) {
            // Nếu list đã có avatar thì dùng luôn, không cần fetch
            if (prov is Map &&
                (prov['avatar'] ?? '').toString().trim().isNotEmpty) {
              _providerFull = Map<String, dynamic>.from(prov);
            } else {
              // Gọi public API lấy chi tiết provider
              try {
                final pres =
                    await http.get(Uri.parse(getPublicProviderInfoUrl(provId)));
                if (pres.statusCode == 200) {
                  _providerFull = json.decode(pres.body)
                      as Map<String, dynamic>; // có avatar/đủ field
                }
              } catch (_) {
                // bỏ qua lỗi phụ
              }
            }
          }
        }

        setState(() {
          request = found;
          _ratingController.text = request?['rating']?.toString() ?? '';
          _commentController.text = request?['comment'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải chi tiết yêu cầu')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi mạng: $e')),
      );
    }
  }

  Future<void> _pay() async {
    setState(() => isPaying = true);
    final res = await http.post(
      Uri.parse('$baseUrl/farmer/requests/${widget.requestId}/pay'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    setState(() => isPaying = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công')),
      );
      fetchRequest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể thanh toán')),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => isResending = true);
    final res = await http.patch(
      Uri.parse('$baseUrl/farmer/requests/${widget.requestId}/resend'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    setState(() => isResending = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi lại yêu cầu thành công')),
      );
      fetchRequest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi lại yêu cầu')),
      );
    }
  }

  Future<void> _rate() async {
    final rating = int.tryParse(_ratingController.text.trim());
    if (rating == null || rating < 1 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập điểm từ 1 đến 5')),
      );
      return;
    }

    setState(() => isRating = true);
    final res = await http.post(
      Uri.parse('$baseUrl/farmer/requests/${widget.requestId}/rate'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': _commentController.text.trim(),
      }),
    );
    setState(() => isRating = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đánh giá thành công')),
      );
      fetchRequest();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi đánh giá')),
      );
    }
  }

  // ========= UI =========
  @override
  Widget build(BuildContext context) {
    final status = request?['status'];
    final paymentStatus = request?['payment_status'];
    final rated = request?['rating'] != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Chi tiết yêu cầu'),
      ),
      backgroundColor: Colors.green.shade50,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : request == null
              ? const Center(child: Text('Không tìm thấy yêu cầu'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // —— Header tóm tắt + avatar bên phải ——
                      _summaryWithAvatar(),
                      const SizedBox(height: 12),
                      const Divider(height: 32),

                      if (status == 'REJECTED')
                        _buildActionButton(
                          icon: Icons.refresh,
                          label: 'Gửi lại yêu cầu',
                          onPressed: isResending ? null : _resend,
                          showLoading: isResending,
                          color: Colors.orange.shade700,
                        ),
                      if (status == 'PENDING')
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'Chỉnh sửa yêu cầu',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DraggableScrollableSheet(
                                expand: false,
                                initialChildSize: 0.95,
                                maxChildSize: 0.95,
                                builder: (_, controller) => Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  padding: const EdgeInsets.only(top: 12),
                                  child: CreateRequestScreen(
                                    token: widget.token,
                                    editingRequest: request,
                                  ),
                                ),
                              ),
                            ).then((_) => fetchRequest());
                          },
                          color: Colors.blueGrey,
                        ),
                      if (status == 'COMPLETED' && paymentStatus == 'UNPAID')
                        _buildActionButton(
                          icon: Icons.payment,
                          label: 'Xác nhận hoàn thành',
                          onPressed: isPaying ? null : _pay,
                          showLoading: isPaying,
                          color: Colors.green.shade700,
                        ),

                      if (status == 'COMPLETED' && paymentStatus == 'PAID') ...[
                        const Text('Đánh giá dịch vụ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Điểm hiện tại: ${request?['rating'] ?? '-'}'),
                        if ((request?['comment'] ?? '').toString().isNotEmpty)
                          Text('Góp ý hiện tại: ${request?['comment']}'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _ratingController,
                          label: 'Điểm (1–5)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _commentController,
                          label: 'Góp ý (tuỳ chọn)',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.star,
                          label: rated ? 'Cập nhật đánh giá' : 'Gửi đánh giá',
                          onPressed: isRating ? null : _rate,
                          showLoading: isRating,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  // —— Header với info bên trái + avatar bên phải ——
  Widget _summaryWithAvatar() {
    final providerLite = request?['provider_id'];

    // name “lite” từ payload list requests
    final nameLite =
        (providerLite is Map ? providerLite['company_name'] : null) ??
            'Chưa có';

    // Ưu tiên dùng providerFull (có avatar); fallback providerLite
    final useProv = _providerFull ??
        (providerLite is Map ? Map<String, dynamic>.from(providerLite) : null);

    final providerName = (useProv?['company_name'] ?? nameLite).toString();
    final avatarUrl = _resolveAvatarUrl(useProv?['avatar']?.toString());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột thông tin bên trái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Dịch vụ', request!['service_type']),
                _buildInfoRow('Cây trồng', request!['crop_type']),
                _buildInfoRow('Diện tích', '${request!['area_ha']} ha'),
                _buildInfoRow('Ngày yêu cầu',
                    request!['preferred_date']?.split('T')[0] ?? '---'),
                const SizedBox(height: 8),
                _buildInfoRow('Trạng thái', request!['status']),
                _buildInfoRow('Thanh toán', request!['payment_status']),
                const SizedBox(height: 8),
                Text('Nhà cung cấp: $providerName'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar bên phải (vùng bạn khoanh)
          CircleAvatar(
            radius: 72,
            backgroundColor: Colors.green.shade100,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    _initials(providerName),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // —— Widgets phụ ——
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? "---"}'),
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
    required Color color,
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
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
