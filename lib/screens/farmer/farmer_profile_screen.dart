import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../auth/login_screen.dart';

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
  String? avatarUrl;
  File? avatarFile;

  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/farmer/profile'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        name = data['name'] ?? '';
        phone = data['phone'] ?? '';
        email = data['email'] ?? '';
        province = data['location']?['province'] ?? '';
        avatarUrl = data['avatar'];
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
      }
    };

    final res = await http.patch(
      Uri.parse('http://10.0.2.2:5000/api/farmer/profile'),
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

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => avatarFile = File(picked.path));

    final ext = picked.path.split('.').last.toLowerCase();
    final mime =
        ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:5000/api/farmer/avatar/upload'),
    );
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.files.add(await http.MultipartFile.fromPath(
      'avatar',
      avatarFile!.path,
      contentType: mime,
    ));

    final response = await request.send();
    final resp = await http.Response.fromStream(response);

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() => avatarUrl = data['avatar']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật avatar thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật avatar thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Tài khoản',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickAndUploadAvatar,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: avatarFile != null
                                    ? FileImage(avatarFile!)
                                    : (avatarUrl != null
                                        ? NetworkImage(
                                            'http://10.0.2.2:5000$avatarUrl')
                                        : null) as ImageProvider<Object>?,
                                child: avatarFile == null && avatarUrl == null
                                    ? const Icon(Icons.person,
                                        size: 48, color: Colors.white)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.edit,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Đăng xuất',
                            style: TextStyle(color: Colors.red),
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
