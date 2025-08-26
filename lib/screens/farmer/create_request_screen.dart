import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class CreateRequestScreen extends StatefulWidget {
  final String token;
  final String? initialProviderId;
  final String? initialServiceType;
  final Map<String, dynamic>? editingRequest;

  const CreateRequestScreen({
    super.key,
    required this.token,
    this.initialProviderId,
    this.initialServiceType,
    this.editingRequest,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String cropType = '';
  double areaHa = 0.0;
  String serviceType = '';
  double latitude = 0.0;
  double longitude = 0.0;
  DateTime? preferredDate;
  String type = 'free';
  List<dynamic> providers = [];
  String? selectedProviderId;
  List<String> availableServices = [];
  double estimatedPrice = 0.0;

  LatLng? _selectedLatLng;
  Position? _currentPosition;

  final List<String> cropOptions = ['Lúa', 'Ngô', 'Khoai', 'Mía'];

  @override
  void initState() {
    super.initState();
    fetchProviders();
    _getCurrentLocation();

    if (widget.editingRequest != null) {
      final req = widget.editingRequest!;
      cropType = req['crop_type'] ?? '';
      areaHa = (req['area_ha'] ?? 0.0).toDouble();
      serviceType = req['service_type'] ?? '';
      preferredDate = req['preferred_date'] != null
          ? DateTime.parse(req['preferred_date']).toLocal()
          : null;

      final coords = req['field_location']?['coordinates'];
      if (coords != null) {
        latitude = coords['lat'] ?? 0.0;
        longitude = coords['lng'] ?? 0.0;
        _selectedLatLng = LatLng(latitude, longitude);
      }

      if (req['provider_id'] != null) {
        selectedProviderId = req['provider_id']['_id'];
        type = 'assigned';
      } else {
        type = 'free';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        updateServiceOptions();
        updateEstimatedPrice();
      });
    }
  }

  Future<void> fetchProviders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/farmer/list-services'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        providers = data;
        if (widget.initialProviderId != null) {
          selectedProviderId = widget.initialProviderId;
          type = 'assigned';
        }
        updateServiceOptions();

        if (widget.initialServiceType != null &&
            availableServices.contains(widget.initialServiceType)) {
          serviceType = widget.initialServiceType!;
        }
        updateEstimatedPrice();
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

  void updateServiceOptions() {
    if (type == 'assigned') {
      final selected = providers.firstWhere(
        (p) => p['_id'] == selectedProviderId,
        orElse: () => null,
      );
      if (selected != null && selected['services'] is List) {
        setState(() {
          availableServices = (selected['services'] as List)
              .map<String>((s) => s['name'] as String)
              .toList();
        });
      }
    } else {
      final allServices = providers.expand((p) => p['services'] ?? []).toList();
      final serviceNames = allServices
          .map((s) => s['name'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      setState(() {
        availableServices = serviceNames;
      });
    }
  }

  void updateEstimatedPrice() {
    if (type == 'assigned' &&
        selectedProviderId != null &&
        serviceType.isNotEmpty &&
        areaHa > 0) {
      final selected = providers.firstWhere(
        (p) => p['_id'] == selectedProviderId,
        orElse: () => null,
      );
      if (selected != null) {
        final matched = (selected['services'] as List?)?.firstWhere(
          (s) => s['name'] == serviceType,
          orElse: () => null,
        );
        if (matched != null && matched['price'] != null) {
          setState(() {
            estimatedPrice = (matched['price'] as num).toDouble() * areaHa;
          });
          return;
        }
      }
    }
    setState(() => estimatedPrice = 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (cropType.isEmpty || serviceType.isEmpty || preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin bắt buộc')),
      );
      return;
    }

    final isEditing = widget.editingRequest != null;
    final payload = {
      'crop_type': cropType,
      'area_ha': areaHa,
      'service_type': serviceType,
      'preferred_date': preferredDate!.toIso8601String(),
      'field_location': {
        'coordinates': {'lat': latitude, 'lng': longitude}
      },
    };

    if (type == 'assigned' && selectedProviderId != null) {
      payload['provider_id'] = selectedProviderId!;
    }

    final uri = isEditing
        ? Uri.parse('$baseUrl/farmer/requests/${widget.editingRequest!['_id']}')
        : Uri.parse('$baseUrl/farmer/requests');

    try {
      final res = await (isEditing
          ? http.patch(uri,
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
              body: json.encode(payload))
          : http.post(uri,
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
              body: json.encode(payload)));

      final body = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ??
                (isEditing ? 'Cập nhật thành công' : 'Tạo yêu cầu thành công')),
          ),
        );
        if (!isEditing) {
          _formKey.currentState?.reset();
          setState(() {
            preferredDate = null;
            selectedProviderId = null;
            estimatedPrice = 0;
          });
        } else {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Lỗi xử lý yêu cầu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _selectedLatLng != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: Text(widget.editingRequest != null
            ? "Chỉnh sửa yêu cầu"
            : "Tạo yêu cầu",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
                        boxShadow: const [
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
                              markerId: const MarkerId("selected"),
                              position: _selectedLatLng!)
                        },
                        onTap: _onMapTap,
                        zoomControlsEnabled: true,
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
                            onChanged: (val) {
                              setState(() {
                                type = val!;
                                selectedProviderId = null;
                                serviceType = '';
                                updateServiceOptions();
                                updateEstimatedPrice();
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          if (type == 'assigned')
                            DropdownButtonFormField<String>(
                              value: selectedProviderId,
                              decoration: const InputDecoration(
                                labelText: 'Chọn nhà cung cấp',
                                border: OutlineInputBorder(),
                              ),
                              items: providers
                                  .map<DropdownMenuItem<String>>((p) =>
                                      DropdownMenuItem<String>(
                                        value: p['_id'],
                                        child: Text(
                                            p['company_name'] ?? 'Không tên'),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedProviderId = val;
                                  serviceType = '';
                                  updateServiceOptions();
                                  updateEstimatedPrice();
                                });
                              },
                            ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: serviceType.isNotEmpty ? serviceType : null,
                            items: availableServices
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Loại dịch vụ',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setState(() {
                                serviceType = val ?? '';
                                updateEstimatedPrice();
                              });
                            },
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Bắt buộc' : null,
                          ),
                          const SizedBox(height: 12),
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
                            initialValue: areaHa > 0 ? areaHa.toString() : '',
                            decoration: const InputDecoration(
                              labelText: 'Diện tích (ha)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              areaHa = double.tryParse(val) ?? 0.0;
                              updateEstimatedPrice();
                            },
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
                                initialDate: preferredDate ??
                                    DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setState(() {
                                  preferredDate = picked;
                                });
                              }
                            },
                          ),
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
                            child: Text(widget.editingRequest != null
                                ? "Lưu chỉnh sửa"
                                : "Gửi yêu cầu"),
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
