import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class CreateRequestScreen extends StatefulWidget {
  final String token;
  const CreateRequestScreen({super.key, required this.token});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String cropType = '';
  double areaHa = 0.0;
  String serviceType = '';
  String province = '';
  double latitude = 0.0;
  double longitude = 0.0;
  DateTime? preferredDate;
  String type = 'free';
  List<dynamic> providers = [];
  String? selectedProviderId;

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/farmer/list-services'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        providers = json.decode(res.body);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (cropType.isEmpty ||
        serviceType.isEmpty ||
        province.isEmpty ||
        preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin bắt buộc')),
      );
      return;
    }

    final payload = {
      'crop_type': cropType,
      'area_ha': areaHa,
      'service_type': serviceType,
      'preferred_date': preferredDate!.toIso8601String(),
      'field_location': {
        'province': province,
        'coordinates': {'lat': latitude, 'lng': longitude}
      },
    };

    if (type == 'assigned' && selectedProviderId != null) {
      payload['provider_id'] = selectedProviderId!;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/farmer/requests'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (!mounted) return;

      if (res.statusCode == 201) {
        final body = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Gửi yêu cầu thành công')),
        );
        _formKey.currentState?.reset();
        setState(() {
          preferredDate = null;
          selectedProviderId = null;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thành công'),
            content: const Text('Bạn có muốn tạo thêm yêu cầu khác không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Có'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Không'),
              ),
            ],
          ),
        );
      } else {
        String errorMsg = 'Gửi yêu cầu thất bại';
        try {
          final body = json.decode(res.body);
          errorMsg = body['message'] ?? errorMsg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Tạo yêu cầu"),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Loại cây trồng',
                      prefixIcon: Icon(Icons.local_florist),
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (val) => cropType = val ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Diện tích (ha)',
                      prefixIcon: Icon(Icons.square_foot),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (val) =>
                        areaHa = double.tryParse(val ?? '') ?? 0.0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Loại dịch vụ',
                      prefixIcon: Icon(Icons.miscellaneous_services),
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (val) => serviceType = val ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tỉnh',
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (val) => province = val ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Vĩ độ (lat)',
                      prefixIcon: Icon(Icons.place),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (val) =>
                        latitude = double.tryParse(val ?? '') ?? 0.0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Kinh độ (lng)',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (val) =>
                        longitude = double.tryParse(val ?? '') ?? 0.0,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Chọn ngày thực hiện'),
                    subtitle: Text(
                        preferredDate?.toLocal().toString().split(' ')[0] ??
                            'Chưa chọn'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          preferredDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Hình thức yêu cầu',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Tự do')),
                      DropdownMenuItem(
                          value: 'assigned', child: Text('Chỉ định')),
                    ],
                    onChanged: (val) => setState(() => type = val!),
                  ),
                  if (type == 'assigned') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedProviderId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn nhà cung cấp',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Chọn nhà cung cấp'),
                      items: providers.map<DropdownMenuItem<String>>((p) {
                        return DropdownMenuItem<String>(
                          value: p['_id'] as String,
                          child: Text(p['company_name'] ?? 'Không tên'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => selectedProviderId = val),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text("Gửi yêu cầu"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
