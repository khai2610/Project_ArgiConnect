import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../utils/constants.dart';
import 'provider_chat_screen.dart';

class ProviderMapScreen extends StatefulWidget {
  final String token;
  const ProviderMapScreen({super.key, required this.token});

  @override
  State<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends State<ProviderMapScreen> {
  Position? _currentPosition;
  GoogleMapController? _mapController;
  final Map<MarkerId, Marker> _markers = {};
  final Map<String, dynamic> _requestMap = {}; // 👈 lưu dữ liệu yêu cầu theo id

  late final String providerId;

  @override
  void initState() {
    super.initState();
    providerId = JwtDecoder.decode(widget.token)['id'];
    _getCurrentLocation();
    _fetchMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      await Geolocator.requestPermission();
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (_) {
      setState(() {
        _currentPosition = Position(
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
        );
      });
    }
  }

  Future<void> _fetchMarkers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/provider/requests'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        for (var req in data) {
          final loc = req['field_location']?['coordinates'];
          if (loc?['lat'] != null && loc?['lng'] != null) {
            final id = req['_id'];
            _requestMap[id] = req; // 👈 lưu lại toàn bộ req theo id

            final crop = req['crop_type'] ?? '';
            final service = req['service_type'] ?? '';
            final status = req['status'] ?? '';

            final marker = Marker(
              markerId: MarkerId(id),
              position: LatLng(loc['lat'], loc['lng']),
              icon: _getMarkerColor(status),
              infoWindow: InfoWindow(
                title: '$crop - $service',
              ),
              onTap: () => _showRequestPopup(req),
            );

            _markers[MarkerId(id)] = marker;
          }
        }
        setState(() {});
      }
    }
  }

  BitmapDescriptor _getMarkerColor(String status) {
    switch (status) {
      case 'PENDING':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'ACCEPTED':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'COMPLETED':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _showRequestPopup(Map<String, dynamic> req) {
    final crop = req['crop_type'] ?? '---';
    final service = req['service_type'] ?? '---';
    final area = req['area_ha']?.toString() ?? '---';
    final date = req['preferred_date'] != null
        ? DateTime.parse(req['preferred_date'])
            .toLocal()
            .toString()
            .split(' ')[0]
        : '---';
    final status = req['status'] ?? '---';
    final phone = req['farmer_id']?['phone'] ?? '---';
    final farmerId = req['farmer_id']?['_id'];
    final farmerName = req['farmer_id']?['name'] ?? 'Nông dân';

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
                if (status == 'PENDING') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Nhận yêu cầu'),
                      onPressed: () => _acceptRequest(req['_id']),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Nhắn tin'),
                    onPressed: () {
                        Navigator.pop(context); // đóng bottom sheet
                        final farmer = req['farmer_id'];
                        final farmerId = farmer?['_id'];
                        final farmerName = farmer?['name'] ?? 'Nông dân';
                        if (farmerId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderChatScreen(
                                token: widget.token,
                                farmerId: farmerId,
                                providerId:
                                    providerId, // 👈 dùng biến đã decode từ token
                                currentUserId:
                                    providerId, // 👈 chính là provider
                                receiverName: farmerName,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Không thể mở cuộc trò chuyện')),
                          );
                        }
                      }
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
    Navigator.pop(context); // đóng popup trước khi gọi API
    final res = await http.patch(
      Uri.parse('$baseUrl/provider/requests/$requestId/accept'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã chấp nhận yêu cầu')));
      _fetchMarkers(); // refresh markers
    } else {
      final body = json.decode(res.body);
      final msg = body['message'] ?? '❌ Lỗi khi chấp nhận';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(10.762622, 106.660172);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ yêu cầu'),
        backgroundColor: Colors.green.shade700,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialPosition, zoom: 13),
        myLocationEnabled: true,
        markers: Set<Marker>.of(_markers.values),
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
