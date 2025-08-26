import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../auth/login_screen.dart';

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
      Uri.parse('http://10.0.2.2:5000/api/provider/profile'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        companyName = data['company_name'] ?? '';
        phone = data['phone'] ?? '';
        email = data['email'] ?? '';
        address = data['address'] ?? '';
        avatarUrl = data['avatar'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateProfile() async {
    final res = await http.patch(
      Uri.parse('http://10.0.2.2:5000/api/provider/profile'),
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

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => avatarFile = File(picked.path));

    final ext = avatarFile!.path.split('.').last.toLowerCase();
    final mimeType =
        (ext == 'png') ? MediaType('image', 'png') : MediaType('image', 'jpeg');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:5000/api/provider/avatar/upload'),
    );
    request.headers['Authorization'] = 'Bearer ${widget.token}';

    request.files.add(
      await http.MultipartFile.fromPath(
        'avatar',
        avatarFile!.path,
        contentType: mimeType,
      ),
    );

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
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Thông tin nhà cung cấp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Avatar UI
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
                              ? NetworkImage('http://10.0.2.2:5000$avatarUrl')
                              : null) as ImageProvider<Object>?,
                      child: avatarFile == null && avatarUrl == null
                          ? const Icon(Icons.business,
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
              const SizedBox(height: 20),

              TextFormField(
                initialValue: companyName,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: 'Tên công ty',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => companyName = val,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: phone,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => phone = val,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: address,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => address = val,
              ),
              const SizedBox(height: 20),
              isEditing
                  ? ElevatedButton.icon(
                      onPressed: updateProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu thay đổi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => setState(() => isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        minimumSize: const Size.fromHeight(48),
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
    );
  }
}
