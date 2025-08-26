import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // 👈 Quan trọng

import '../../utils/constants.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String role = farmerRole;
  String email = '';
  String password = '';
  String phone = '';
  String name = '';
  String location = '';
  String companyName = '';
  String address = '';
  File? avatarFile;
  bool isLoading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        avatarFile = File(picked.path);
      });
    }
  }

  Future<void> _register() async {
    _formKey.currentState!.save();
    setState(() => isLoading = true);

    try {
      final uri = Uri.parse(authRegisterEndpoint);
      final request = http.MultipartRequest('POST', uri);

      request.fields['role'] = role;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['phone'] = phone;

      if (role == farmerRole) {
        request.fields['name'] = name;
        request.fields['location'] = json.encode({
          'province': location,
          'coordinates': {'lat': 0.0, 'lng': 0.0}
        });
      } else {
        request.fields['company_name'] = companyName;
        request.fields['address'] = address;
      }

      if (avatarFile != null) {
        final ext = avatarFile!.path.split('.').last.toLowerCase();
        final mime = (ext == 'png')
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg');

        final avatar = await http.MultipartFile.fromPath(
          'avatar',
          avatarFile!.path,
          contentType: mime,
        );
        request.files.add(avatar);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final message =
            json.decode(response.body)['message'] ?? 'Đăng ký thất bại';
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối server')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset(
                'assets/images/drone_no_bg_final.png',
                height: 100,
              ),
              const SizedBox(height: 4),
              Text(
                "Đăng ký",
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 450),
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
                      // Avatar Picker
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: avatarFile != null
                              ? FileImage(avatarFile!)
                              : null,
                          child: avatarFile == null
                              ? const Icon(Icons.camera_alt,
                                  size: 32, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: role,
                        items: const [
                          DropdownMenuItem(
                              value: farmerRole, child: Text("Nông dân")),
                          DropdownMenuItem(
                              value: providerRole, child: Text("Nhà cung cấp")),
                        ],
                        onChanged: (val) => setState(() => role = val!),
                        decoration: const InputDecoration(
                          labelText: 'Vai trò',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => email = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSaved: (v) => password = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => phone = v ?? '',
                      ),
                      const SizedBox(height: 16),
                      if (role == farmerRole) ...[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Tên người dùng',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (v) => name = v ?? '',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Tỉnh/Thành (location)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (v) => location = v ?? '',
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (role == providerRole) ...[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Tên công ty',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (v) => companyName = v ?? '',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ công ty',
                            prefixIcon: Icon(Icons.map_outlined),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (v) => address = v ?? '',
                        ),
                        const SizedBox(height: 16),
                      ],
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _register,
                                child: const Text("Đăng ký"),
                              ),
                            ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        child: const Text("Đã có tài khoản? Đăng nhập"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
