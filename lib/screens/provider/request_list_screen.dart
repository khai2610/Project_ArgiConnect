import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'provider_map_screen.dart';
import 'request_detail_screen.dart';

class RequestListScreen extends StatefulWidget {
  final String token;
  const RequestListScreen({super.key, required this.token});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  List<dynamic> requests = [];
  String filterStatus = 'ALL';
  int completedToday = 0;
  int revenueToday = 0;
  bool isLoading = true;
  Position? _currentPosition;
  final Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchRequests();
    fetchSummary();
  }

  Future<void> _getCurrentLocation() async {
    try {
      await Geolocator.requestPermission();
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _currentPosition = Position(
            latitude: 10.762622,
            longitude: 106.660172,
            timestamp: DateTime.now(),
            accuracy: 1,
            altitudeAccuracy: 1,
            headingAccuracy: 1,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
          ));
    }
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    final res = await http.get(
      Uri.parse('$baseUrl/provider/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        setState(() => requests = data);
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchSummary() async {
    final res = await http.get(
      Uri.parse(providerSummaryEndpoint),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      setState(() {
        completedToday = json['completedToday'] ?? 0;
        revenueToday = json['revenueToday'] ?? 0;
      });
    }
  }

  double _parseArea(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  List<dynamic> get filteredRequests {
    if (filterStatus == 'ALL') return requests;
    return requests.where((r) => r['status'] == filterStatus).toList();
  }

  List<dynamic> get ratedRequests =>
      requests.where((r) => r['rating'] != null).toList();

  Widget _buildRequestCard(dynamic req) {
    final crop = req['crop_type'] ?? '---';
    final service = req['service_type'] ?? '---';
    final area = _parseArea(req['area_ha']);
    final date = req['preferred_date'] != null
        ? DateTime.parse(req['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';
    final status = req['status'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text('$crop - $service'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diện tích: $area ha'),
            Text('Ngày thực hiện: $date'),
            Text('Trạng thái: $status'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(
                token: widget.token,
                requestId: req['_id'],
              ),
            ),
          );
          if (result == true) {
            fetchRequests();
            fetchSummary();
          }
        },
      ),
    );
  }

  Widget _buildRatingCard(dynamic req) {
    final farmer = req['farmer_id'];
    final comment = req['comment'];
    final rating = req['rating'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$rating / 5',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (comment != null && comment.toString().trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text('📝 Nhận xét: $comment'),
              ),
            if (farmer != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('👤 ${farmer['name'] ?? 'Nông dân'}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // ✅ Hôm nay đã bay
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.work, color: Colors.green, size: 24),
                      SizedBox(width: 6),
                      Text(
                        'Hôm nay đã bay',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedToday',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ✅ Doanh thu hôm nay
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.attach_money, color: Colors.orange, size: 24),
                      SizedBox(width: 6),
                      Text(
                        'Doanh thu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${revenueToday}đ',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined),
          const SizedBox(width: 8),
          const Text('Lọc theo trạng thái:'),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: filterStatus,
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
              DropdownMenuItem(value: 'PENDING', child: Text('Chờ xử lý')),
              DropdownMenuItem(value: 'ACCEPTED', child: Text('Đã nhận')),
              DropdownMenuItem(value: 'COMPLETED', child: Text('Hoàn thành')),
              DropdownMenuItem(value: 'REJECTED', child: Text('Đã từ chối')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => filterStatus = value);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Tất cả yêu cầu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              fetchRequests();
              fetchSummary();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRequests,
              child: ListView(
                children: [
                  _buildSummaryCard(),
                  _buildFilterDropdown(),
                  ...filteredRequests.map(_buildRequestCard),
                  const SizedBox(height: 12),
                  if (ratedRequests.isNotEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '📝 Đánh giá từ nông dân',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ...ratedRequests.map(_buildRatingCard),
                ],
              ),
            ),
    );
  }
}
