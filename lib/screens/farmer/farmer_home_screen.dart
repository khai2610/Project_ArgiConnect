import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart';
import 'farmer_profile_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  final String token;
  const FarmerHomeScreen({super.key, required this.token});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> providers = [];

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/farmer/list-services'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        providers = json.decode(res.body);
      });
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildProviderList() {
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final List<dynamic> services = provider['services'] ?? [];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExpansionTile(
            title: Text(provider['company_name'] ?? 'Không tên'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: ${provider['email'] ?? ''}"),
                Text("SĐT: ${provider['phone'] ?? ''}"),
                Text("Địa chỉ: ${provider['address'] ?? ''}"),
              ],
            ),
            children: services.map((service) {
              return ListTile(
                title: Text(service['name'] ?? 'Dịch vụ'),
                subtitle: Text(service['description'] ?? ''),
                leading: const Icon(Icons.agriculture),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildProviderList();
      case 1:
        return CreateRequestScreen(token: widget.token);
      case 2:
        return MyRequestsScreen(token: widget.token);
      case 3:
        return FarmerProfileScreen(token: widget.token);
      default:
        return const Center(child: Text("Không có nội dung"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nông dân'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _buildMainContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Nhà cung cấp'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Tạo yêu cầu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Yêu cầu của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
