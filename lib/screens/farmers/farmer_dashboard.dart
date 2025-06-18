import 'package:flutter/material.dart';
import 'package:argi_project/models/drone_service.dart';
import 'package:argi_project/services/api_service.dart';
import 'booking_form_screen.dart';
import 'dart:convert';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  List<DroneService> services = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    try {
      final res = await ApiService.get('/api/services/all');
      if (res.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(res.body);
        setState(() {
          services = jsonList.map((e) => DroneService.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dịch vụ: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dịch vụ Drone')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
              ? const Center(child: Text('Không có dịch vụ nào hiện có'))
              : ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(service.serviceName),
                        subtitle: Text(
                          'Giá: ${service.pricePerHa.toStringAsFixed(0)} đ/ha\n'
                          'Khu vực: ${service.availableAreas.join(", ")}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingFormScreen(service: service),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
