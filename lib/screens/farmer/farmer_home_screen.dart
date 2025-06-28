import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart';
import 'farmer_profile_screen.dart';
import 'approved_providers_screen.dart';
import 'farmer_invoice_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  final String token;
  const FarmerHomeScreen({super.key, required this.token});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> providers = [];

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

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return ApprovedProvidersScreen(token: widget.token);
      case 1:
        return CreateRequestScreen(token: widget.token);
      case 2:
        return MyRequestsScreen(token: widget.token);
      case 3:
        return FarmerInvoiceScreen(token: widget.token);
      case 4:
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
          BottomNavigationBarItem(
              icon: Icon(Icons.add), label: 'Tạo yêu cầu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Yêu cầu của tôi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt), label: 'Hóa đơn'), 
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
