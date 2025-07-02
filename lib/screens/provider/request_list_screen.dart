import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'request_detail_screen.dart';

class RequestListScreen extends StatefulWidget {
  final String token;
  const RequestListScreen({super.key, required this.token});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;
  Position? _currentPosition;
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchRequests();
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

  BitmapDescriptor _getMarkerColor(String status) {
    switch (status) {
      case 'PENDING':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'ACCEPTED':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'COMPLETED':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'REJECTED':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> fetchRequests() async {
    try {
      setState(() => isLoading = true);
      final res = await http.get(
        Uri.parse('$baseUrl/provider/requests'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          setState(() {
            requests = data;
            _setMarkers();
          });
        }
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _setMarkers() {
    _markers.clear();
    for (var req in requests) {
      final loc = req['field_location']?['coordinates'];
      if (loc != null && loc['lat'] != null && loc['lng'] != null) {
        final id = req['_id'];
        final crop = req['crop_type'] ?? '---';
        final service = req['service_type'] ?? '---';
        final status = req['status'] ?? '---';
        final phone = req['farmer_id']?['phone'] ?? '---';
        final area = _parseArea(req['area_ha']);

        final marker = Marker(
          markerId: MarkerId(id),
          position: LatLng(loc['lat'], loc['lng']),
          icon: _getMarkerColor(status),
          infoWindow: InfoWindow(
            title: '$crop - $service',
            snippet: 'DT: ${area}ha | $status\n📞 $phone',
            onTap: () => _showRequestInfo(req),
          ),
        );
        _markers[MarkerId(id)] = marker;
      }
    }
  }

  double _parseArea(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  void _showRequestInfo(Map<String, dynamic> req) {
    final crop = req['crop_type'] ?? '---';
    final service = req['service_type'] ?? '---';
    final area = _parseArea(req['area_ha']);
    final date = req['preferred_date'] != null
        ? DateTime.parse(req['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';
    final status = req['status'] ?? '---';
    final phone = req['farmer_id']?['phone'] ?? '---';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$crop - $service',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Diện tích: $area ha'),
            Text('Ngày thực hiện: $date'),
            Text('Trạng thái: $status'),
            Text('📞 $phone'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Chấp nhận'),
                    onPressed: () => _acceptRequest(req['_id']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Nhắn tin'),
                    onPressed: () => _chatWithFarmer(req['farmer_id']),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/provider/requests/$requestId/accept'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã chấp nhận yêu cầu')));
      fetchRequests();
    } else {
      final body = json.decode(res.body);
      final msg = body['message'] ?? '❌ Lỗi khi chấp nhận';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _chatWithFarmer(dynamic farmer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('💬 Mở chat với ${farmer?['name'] ?? 'nông dân'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(10.762622, 106.660172);

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Yêu cầu gần bạn'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchRequests),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade700, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 4))
                  ],
                ),
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: initialPosition, zoom: 13),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: Set<Marker>.of(_markers.values),
                  onMapCreated: (controller) => _mapController = controller,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchRequests,
                    child: ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final crop = req['crop_type'] ?? '---';
                        final service = req['service_type'] ?? '---';
                        final area = _parseArea(req['area_ha']);
                        final date = req['preferred_date'] != null
                            ? DateTime.parse(req['preferred_date'])
                                .toLocal()
                                .toString()
                                .split(' ')[0]
                            : '---';
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            title: Text('$crop - $service'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Diện tích: $area ha'),
                                Text('Ngày thực hiện: $date'),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _showRequestInfo(req),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
