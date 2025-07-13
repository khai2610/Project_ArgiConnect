import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'request_list_screen.dart';
import 'service_manage_screen.dart';
import 'invoice_screen.dart';
import 'provider_profile_screen.dart';
import 'provider_chat_list_screen.dart'; // ✅ Sửa import đúng

class ProviderHomeScreen extends StatefulWidget {
  final String token;
  const ProviderHomeScreen({super.key, required this.token});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;

  void _goToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderChatListScreen(
            token: widget.token), // ✅ Đúng màn hình chat provider
      ),
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
      backgroundColor: const Color(0xFFF7FDF7), // nền nhạt nổi logo
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: Row(
          children: [
            Image.asset(
              'assets/images/drone_white_no_bg.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              'Agri Drone',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _goToChat,
            icon: const Icon(Icons.chat),
            tooltip: 'Tin nhắn',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.green.shade700,
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
