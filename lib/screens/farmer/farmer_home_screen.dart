import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'create_request_screen.dart';
import 'my_requests_screen.dart';
import 'farmer_profile_screen.dart';
import 'approved_providers_screen.dart';
import 'farmer_invoice_screen.dart';
import '../chat_list_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  final String token;
  const FarmerHomeScreen({super.key, required this.token});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  int _selectedIndex = 0;
  late String farmerId;

  @override
  void initState() {
    super.initState();
    final decoded = JwtDecoder.decode(widget.token);
    farmerId = decoded['id']; // 👈 lấy id từ token
  }

  void _goToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatListScreen(
          token: widget.token,
          currentUserId: farmerId,
          currentRole: 'farmer',
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return ApprovedProvidersScreen(
          token: widget.token,
          farmerId: farmerId, // ✅ truyền vào
        );
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
      backgroundColor: const Color(0xFFF7FDF7),
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
      body: _buildMainContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Nhà cung cấp'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Tạo yêu cầu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Yêu cầu của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Hóa đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
