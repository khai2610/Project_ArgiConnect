import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class FarmerProfileScreen extends StatefulWidget {
  final String token;
  const FarmerProfileScreen({super.key, required this.token});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isEditing = false;

  String name = '';
  String phone = '';
  String email = '';
  String province = '';
  double latitude = 0.0;
  double longitude = 0.0;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/farmer/profile'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        name = data['name'] ?? '';
        phone = data['phone'] ?? '';
        email = data['email'] ?? '';
        province = data['location']?['province'] ?? '';
        latitude = (data['location']?['coordinates']?['lat'] ?? 0.0).toDouble();
        longitude =
            (data['location']?['coordinates']?['lng'] ?? 0.0).toDouble();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải thông tin')),
      );
    }
  }

  Future<void> updateProfile() async {
    final body = {
      'name': name,
      'phone': phone,
      'location': {
        'province': province,
        'coordinates': {'lat': latitude, 'lng': longitude}
      }
    };

    final res = await http.patch(
      Uri.parse('$baseUrl/farmer/profile'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
      setState(() => isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Tài khoản'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
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
                          initialValue: name,
                          enabled: isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => name = val,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: phone,
                          enabled: isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => phone = val,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: email,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const Divider(height: 32),
                        TextFormField(
                          initialValue: province,
                          enabled: isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Tỉnh/Thành',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => province = val,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: latitude.toString(),
                          enabled: isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Vĩ độ (lat)',
                            prefixIcon: Icon(Icons.map_outlined),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              latitude = double.tryParse(val) ?? 0.0,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: longitude.toString(),
                          enabled: isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Kinh độ (lng)',
                            prefixIcon: Icon(Icons.map),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              longitude = double.tryParse(val) ?? 0.0,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isEditing
                                ? updateProfile
                                : () => setState(() => isEditing = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                Text(isEditing ? 'Lưu thay đổi' : 'Chỉnh sửa'),
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
