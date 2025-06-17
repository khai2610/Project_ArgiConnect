import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '';
  bool isLoading = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      Session.authToken = data['token'];
      Session.role = data['user']['role'];

      Navigator.pushReplacementNamed(context, '/${Session.role}');
    } else {
      final msg = jsonDecode(res.body)['message'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(decoration: InputDecoration(labelText: 'Email'), onSaved: (val) => email = val ?? '', validator: (val) => val!.isEmpty ? 'Không để trống' : null),
              TextFormField(decoration: InputDecoration(labelText: 'Mật khẩu'), obscureText: true, onSaved: (val) => password = val ?? '', validator: (val) => val!.isEmpty ? 'Không để trống' : null),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading ? CircularProgressIndicator() : Text('Đăng nhập'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text('Chưa có tài khoản? Đăng ký'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
