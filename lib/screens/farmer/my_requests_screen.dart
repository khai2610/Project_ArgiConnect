import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class MyRequestsScreen extends StatefulWidget {
  final String token;
  const MyRequestsScreen({super.key, required this.token});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    final res = await http.get(
      Uri.parse('$baseUrl/farmer/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        requests = json.decode(res.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải yêu cầu')),
      );
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final provider = req['provider_id'];
    final crop = req['crop_type'] ?? 'Không rõ';
    final service = req['service_type'] ?? 'Không rõ';
    final area = req['area_ha'] ?? 0.0;
    final date = req['preferred_date'] != null
        ? DateTime.parse(req['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : 'Chưa chọn';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text('$crop - $service'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diện tích: $area ha'),
            Text('Ngày yêu cầu: $date'),
            Text(
                'Nhà cung cấp: ${provider != null ? provider['company_name'] : 'Tự do'}'),
            Text('Trạng thái: ${req['status']}'),
            Text('Thanh toán: ${req['payment_status']}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return const Center(child: Text('Chưa có yêu cầu nào'));
    }

    return RefreshIndicator(
      onRefresh: fetchRequests,
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(requests[index]);
        },
      ),
    );
  }
}
