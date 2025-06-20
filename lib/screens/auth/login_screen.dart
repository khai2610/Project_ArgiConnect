import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../farmer/farmer_home_screen.dart';
import '../provider/provider_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String role = farmerRole;
  String email = '';
  String password = '';
  bool isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(authLoginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = body['token'];

        if (!mounted) return;
        if (role == farmerRole) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FarmerHomeScreen(token: token)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProviderHomeScreen(token: token)),
          );
        }
      } else {
        final message = body['message'] ?? 'Đăng nhập thất bại';
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
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
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
                decoration: const InputDecoration(labelText: 'Vai trò'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    val!.isEmpty ? 'Email không được để trống' : null,
                onSaved: (val) => email = val ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (val) =>
                    val!.isEmpty ? 'Mật khẩu không được để trống' : null,
                onSaved: (val) => password = val ?? '',
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text("Đăng nhập"),
                    ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text("Chưa có tài khoản? Đăng ký"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
