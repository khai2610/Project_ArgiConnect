import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  LatLng? _selectedLatLng;
  Position? _currentPosition;

  final List<String> cropOptions = ['Lúa', 'Ngô', 'Khoai', 'Mía'];
  final List<String> serviceOptions = [
    'Phun thuốc',
    'Tưới tiêu',
    'Gặt',
    'Cày xới'
  ];

  @override
  void initState() {
    super.initState();
    fetchProviders();
    _getCurrentLocation();
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

  Future<void> _getCurrentLocation() async {
    await Geolocator.requestPermission();
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _selectedLatLng = LatLng(position.latitude, position.longitude);
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLatLng = point;
      latitude = point.latitude;
      longitude = point.longitude;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (cropType.isEmpty ||
        serviceType.isEmpty ||
        province.isEmpty ||
        preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin bắt buộc')),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _selectedLatLng != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Tạo yêu cầu"),
      ),
      body: isReady
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.green.shade700, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLatLng!,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId("selected"),
                            position: _selectedLatLng!,
                          )
                        },
                        onTap: _onMapTap,
                        zoomControlsEnabled: true,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          DropdownButtonFormField<String>(
                            value: cropType.isNotEmpty ? cropType : null,
                            items: cropOptions
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Loại cây trồng',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) =>
                                setState(() => cropType = val ?? ''),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Bắt buộc' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Diện tích (ha)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (val) =>
                                areaHa = double.tryParse(val ?? '') ?? 0.0,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: serviceType.isNotEmpty ? serviceType : null,
                            items: serviceOptions
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Loại dịch vụ',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) =>
                                setState(() => serviceType = val ?? ''),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Bắt buộc' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Tỉnh',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (val) => province = val ?? '',
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            title: const Text('Chọn ngày thực hiện'),
                            subtitle: Text(preferredDate != null
                                ? preferredDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0]
                                : 'Chưa chọn'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.now().add(Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate:
                                    DateTime.now().add(Duration(days: 30)),
                              );
                              if (picked != null) {
                                setState(() {
                                  preferredDate = picked;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: type,
                            decoration: const InputDecoration(
                              labelText: 'Hình thức yêu cầu',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'free', child: Text('Tự do')),
                              DropdownMenuItem(
                                  value: 'assigned', child: Text('Chỉ định')),
                            ],
                            onChanged: (val) => setState(() => type = val!),
                          ),
                          if (type == 'assigned') ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedProviderId,
                              decoration: const InputDecoration(
                                labelText: 'Chọn nhà cung cấp',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Chọn nhà cung cấp'),
                              items:
                                  providers.map<DropdownMenuItem<String>>((p) {
                                return DropdownMenuItem<String>(
                                  value: p['_id'] as String,
                                  child: Text(p['company_name'] ?? 'Không tên'),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => selectedProviderId = val),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submit,
                            child: const Text("Gửi yêu cầu"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
