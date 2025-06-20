import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _register() async {
    _formKey.currentState!.save();
    final payload = {
      'role': role,
      'email': email,
      'password': password,
      'phone': phone,
    };

    if (role == farmerRole) {
      payload['name'] = name;
      payload['location'] = location;
    } else {
      payload['company_name'] = companyName;
      payload['address'] = address;
    }

    final response = await http.post(
      Uri.parse(authRegisterEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 201) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công")),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      final message =
          json.decode(response.body)['message'] ?? 'Đăng ký thất bại';
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: farmerRole, child: Text("Nông dân")),
                  DropdownMenuItem(
                      value: providerRole, child: Text("Nhà cung cấp")),
                ],
                onChanged: (val) => setState(() => role = val!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onSaved: (v) => email = v ?? ''),
              TextFormField(
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  onSaved: (v) => password = v ?? ''),
              TextFormField(
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  onSaved: (v) => phone = v ?? ''),
              if (role == farmerRole) ...[
                TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Tên người dùng'),
                    onSaved: (v) => name = v ?? ''),
                TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Địa chỉ (location)'),
                    onSaved: (v) => location = v ?? ''),
              ],
              if (role == providerRole) ...[
                TextFormField(
                    decoration: const InputDecoration(labelText: 'Tên công ty'),
                    onSaved: (v) => companyName = v ?? ''),
                TextFormField(
                    decoration: const InputDecoration(labelText: 'Địa chỉ'),
                    onSaved: (v) => address = v ?? ''),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _register, child: const Text("Đăng ký")),
            ],
          ),
        ),
      ),
    );
  }
}
