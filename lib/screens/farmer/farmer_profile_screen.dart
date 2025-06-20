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
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              initialValue: name,
              enabled: isEditing,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              onChanged: (val) => name = val,
            ),
            TextFormField(
              initialValue: phone,
              enabled: isEditing,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              onChanged: (val) => phone = val,
            ),
            TextFormField(
              initialValue: email,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const Divider(),
            TextFormField(
              initialValue: province,
              enabled: isEditing,
              decoration: const InputDecoration(labelText: 'Tỉnh/Thành'),
              onChanged: (val) => province = val,
            ),
            TextFormField(
              initialValue: latitude.toString(),
              enabled: isEditing,
              decoration: const InputDecoration(labelText: 'Vĩ độ (lat)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => latitude = double.tryParse(val) ?? 0.0,
            ),
            TextFormField(
              initialValue: longitude.toString(),
              enabled: isEditing,
              decoration: const InputDecoration(labelText: 'Kinh độ (lng)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => longitude = double.tryParse(val) ?? 0.0,
            ),
            const SizedBox(height: 20),
            if (!isEditing)
              ElevatedButton(
                onPressed: () => setState(() => isEditing = true),
                child: const Text('Chỉnh sửa'),
              ),
            if (isEditing)
              ElevatedButton(
                onPressed: updateProfile,
                child: const Text('Lưu thay đổi'),
              ),
          ],
        ),
      ),
    );
  }
}
