import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String token;
  const ProviderProfileScreen({super.key, required this.token});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool isLoading = true;
  bool isEditing = false;

  String companyName = '';
  String phone = '';
  String email = '';
  String address = '';

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/provider/profile'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        companyName = data['company_name'] ?? '';
        phone = data['phone'] ?? '';
        email = data['email'] ?? '';
        address = data['address'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateProfile() async {
    final res = await http.patch(
      Uri.parse('$baseUrl/provider/profile'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'company_name': companyName,
        'phone': phone,
        'address': address,
      }),
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
      child: ListView(
        children: [
          TextFormField(
            initialValue: companyName,
            enabled: isEditing,
            decoration: const InputDecoration(labelText: 'Tên công ty'),
            onChanged: (val) => companyName = val,
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
          TextFormField(
            initialValue: address,
            enabled: isEditing,
            decoration: const InputDecoration(labelText: 'Địa chỉ'),
            onChanged: (val) => address = val,
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
    );
  }
}
