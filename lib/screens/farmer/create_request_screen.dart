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
  String type = 'free'; // hoặc 'assigned'

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

    final payload = {
      'crop_type': cropType,
      'area_ha': areaHa,
      'service_type': serviceType,
      'preferred_date': preferredDate?.toIso8601String(),
      'field_location': {
        'province': province,
        'coordinates': {'lat': latitude, 'lng': longitude}
      },
    };

    if (type == 'assigned' && selectedProviderId != null) {
      payload['provider_id'] = selectedProviderId;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/farmer/requests'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    final body = json.decode(res.body);
    if (res.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['message'] ?? 'Gửi yêu cầu thành công')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['message'] ?? 'Gửi yêu cầu thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tạo yêu cầu")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Loại cây trồng'),
                onSaved: (val) => cropType = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Diện tích (ha)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => areaHa = double.tryParse(val ?? '') ?? 0.0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Loại dịch vụ'),
                onSaved: (val) => serviceType = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tỉnh'),
                onSaved: (val) => province = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Vĩ độ (lat)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => latitude = double.tryParse(val ?? '') ?? 0.0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Kinh độ (lng)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => longitude = double.tryParse(val ?? '') ?? 0.0,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Chọn ngày thực hiện'),
                subtitle:
                    Text(preferredDate?.toLocal().toString() ?? 'Chưa chọn'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
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
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('Tự do')),
                  DropdownMenuItem(value: 'assigned', child: Text('Chỉ định')),
                ],
                onChanged: (val) => setState(() => type = val!),
              ),
              if (type == 'assigned')
              DropdownButtonFormField<String>(
                value: selectedProviderId,
                hint: const Text('Chọn nhà cung cấp'),
                items: providers.map<DropdownMenuItem<String>>((p) {
                  return DropdownMenuItem<String>(
                    value: p['_id'] as String,
                    child: Text(p['company_name'] ?? 'Không tên'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedProviderId = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _submit, child: const Text("Gửi yêu cầu")),
            ],
          ),
        ),
      ),
    );
  }
}
