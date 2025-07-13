import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../chat_screen.dart';

class ProviderDetailScreen extends StatefulWidget {
  final String farmerId;
  final String providerId;
  final String token;

  const ProviderDetailScreen({
    required this.providerId,
    required this.farmerId,
    required this.token,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  late Future<Map<String, dynamic>> _providerFuture;
  late Future<List<dynamic>> _servicesFuture;

  bool showRequestForm = false;
  String? selectedService;

  final TextEditingController cropController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _providerFuture = fetchProvider(widget.providerId);
    _servicesFuture = fetchServices(widget.providerId);
  }

  Future<Map<String, dynamic>> fetchProvider(String id) async {
    final res = await http.get(Uri.parse(getPublicProviderInfoUrl(id)));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Không thể tải thông tin provider');
  }

  Future<List<dynamic>> fetchServices(String id) async {
    final res = await http.get(Uri.parse(getPublicProviderServicesUrl(id)));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Không thể tải danh sách dịch vụ');
  }

  Future<void> submitRequest() async {
    if (cropController.text.isEmpty ||
        areaController.text.isEmpty ||
        selectedDate == null ||
        selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    final res = await http.post(
      Uri.parse(createRequestEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'provider_id': widget.providerId,
        'service_type': selectedService,
        'crop_type': cropController.text,
        'area_ha': double.tryParse(areaController.text) ?? 0,
        'preferred_date': selectedDate!.toIso8601String(),
      }),
    );

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi yêu cầu thành công')),
      );
      setState(() {
        showRequestForm = false;
        selectedService = null;
        cropController.clear();
        areaController.clear();
        selectedDate = null;
      });
    } else {
      debugPrint('Lỗi gửi yêu cầu: ${res.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi gửi yêu cầu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Thông tin nhà cung cấp'),
      ),
      body: FutureBuilder(
        future: Future.wait([_providerFuture, _servicesFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final provider = (snapshot.data as List)[0] as Map<String, dynamic>;
          final services = (snapshot.data as List)[1] as List<dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider['company_name'] ?? 'Không rõ tên công ty',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Email: ${provider['email'] ?? ''}'),
                Text('SĐT: ${provider['phone'] ?? ''}'),
                Text('Địa chỉ: ${provider['address'] ?? ''}'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          farmerId: widget.farmerId,
                          providerId: widget.providerId,
                          currentUserId: widget.farmerId,
                          currentRole: farmerRole,
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Gửi tin nhắn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const Divider(height: 32),
                const Text(
                  'Dịch vụ cung cấp:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...services.map((s) => Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: ListTile(
                        title: Text(s['name']),
                        subtitle: Text(s['description'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showRequestForm = true;
                              selectedService = s['name'];
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                          ),
                          child: const Text('Gửi yêu cầu'),
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
                if (showRequestForm)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin gửi yêu cầu',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (selectedService != null)
                          Text('Dịch vụ đã chọn: $selectedService'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: cropController,
                          decoration: const InputDecoration(
                            labelText: 'Loại cây trồng',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: areaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Diện tích (ha)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(selectedDate != null
                                ? '${selectedDate!.toLocal()}'.split(' ')[0]
                                : 'Chưa chọn ngày'),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                              ),
                              child: const Text('Chọn ngày'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text('Xác nhận gửi yêu cầu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: submitRequest,
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
