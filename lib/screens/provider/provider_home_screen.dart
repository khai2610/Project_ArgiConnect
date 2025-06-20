import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
// Import các màn hình con sau khi bạn tạo
import 'request_list_screen.dart';
import 'service_manage_screen.dart';
import 'invoice_screen.dart';
import 'provider_profile_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  final String token;
  const ProviderHomeScreen({super.key, required this.token});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return RequestListScreen(token: widget.token);
      case 1:
        return ServiceManageScreen(token: widget.token);
      case 2:
        return InvoiceScreen(token: widget.token);
      case 3:
        return ProviderProfileScreen(token: widget.token);
      default:
        return const Center(child: Text('Không có nội dung'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhà cung cấp'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Yêu cầu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.home_repair_service), label: 'Dịch vụ'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Hóa đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
