import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'request_detail_screen.dart';

// 👇 Gộp bộ lọc
class FilterOption {
  final String label;
  final String status;
  final String type;

  const FilterOption(this.label, this.status, this.type);
}

class RequestListScreen extends StatefulWidget {
  final String token;
  const RequestListScreen({super.key, required this.token});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;

  final List<FilterOption> filterOptions = const [
    FilterOption('Tất cả', 'ALL', 'ALL'),
    FilterOption('Đang chờ - Tự do', 'PENDING', 'UNASSIGNED'),
    FilterOption('Đang chờ - Chỉ định', 'PENDING', 'ASSIGNED'),
    FilterOption('Đã nhận - Tự do', 'ACCEPTED', 'UNASSIGNED'),
    FilterOption('Đã nhận - Chỉ định', 'ACCEPTED', 'ASSIGNED'),
    FilterOption('Hoàn thành', 'COMPLETED', 'ALL'),
    FilterOption('Từ chối', 'REJECTED', 'ALL'),
  ];

  FilterOption selectedFilter = const FilterOption('Tất cả', 'ALL', 'ALL');

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    final res = await http.get(
      Uri.parse('$baseUrl/provider/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        requests = json.decode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải danh sách yêu cầu')),
      );
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final farmer = req['farmer_id'];
    final crop = req['crop_type'] ?? '---';
    final service = req['service_type'] ?? '---';
    final area = req['area_ha'] ?? 0;
    final date = req['preferred_date'] != null
        ? DateTime.parse(req['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';
    final status = req['status'];

    // Màu & icon theo trạng thái
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'ACCEPTED':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text('$crop - $service'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diện tích: $area ha'),
            Text('Ngày thực hiện: $date'),
            Text('Nông dân: ${farmer?['name'] ?? 'Không rõ'}'),
            Text('Trạng thái: $status', style: TextStyle(color: statusColor)),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(
                requestId: req['_id'],
                token: widget.token,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final filteredRequests = requests.where((r) {
      final matchStatus = selectedFilter.status == 'ALL' ||
          r['status'] == selectedFilter.status;
      final isAssigned = r['provider_id'] != null;
      final matchType = switch (selectedFilter.type) {
        'ALL' => true,
        'ASSIGNED' => isAssigned,
        'UNASSIGNED' => !isAssigned,
        _ => true,
      };
      return matchStatus && matchType;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Lọc:'),
              const SizedBox(width: 12),
              DropdownButton<FilterOption>(
                value: selectedFilter,
                items: filterOptions
                    .map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedFilter = value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchRequests,
            child: filteredRequests.isEmpty
                ? const Center(child: Text('Không có yêu cầu nào phù hợp'))
                : ListView.builder(
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(filteredRequests[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
