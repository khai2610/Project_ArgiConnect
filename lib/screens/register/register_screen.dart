import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '',
      email = '',
      password = '',
      phone = '',
      location = '',
      role = 'farmer';
  final List<String> roles = ['farmer', 'provider', 'admin'];
  bool isLoading = false;

  void register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'location': location,
        'phone': phone,
      }),
    );

    setState(() => isLoading = false);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đăng ký thành công')));
      Navigator.pop(context);
    } else {
      final msg = jsonDecode(res.body)['message'];
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                  decoration: InputDecoration(labelText: 'Họ tên'),
                  onSaved: (val) => name = val ?? '',
                  validator: (val) => val!.isEmpty ? 'Không để trống' : null),
              TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  onSaved: (val) => email = val ?? '',
                  validator: (val) => val!.isEmpty ? 'Không để trống' : null),
              TextFormField(
                  decoration: InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                  onSaved: (val) => password = val ?? '',
                  validator: (val) =>
                      val!.length < 6 ? 'Tối thiểu 6 ký tự' : null),
              DropdownButtonFormField(
                value: role,
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => role = val!),
                decoration: InputDecoration(labelText: 'Vai trò'),
              ),
              TextFormField(
                  decoration: InputDecoration(labelText: 'Địa chỉ'),
                  onSaved: (val) => location = val ?? ''),
              TextFormField(
                  decoration: InputDecoration(labelText: 'SĐT'),
                  onSaved: (val) => phone = val ?? ''),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : register,
                child:
                    isLoading ? CircularProgressIndicator() : Text('Đăng ký'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
