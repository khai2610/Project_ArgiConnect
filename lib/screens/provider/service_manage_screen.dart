import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class ServiceManageScreen extends StatefulWidget {
  final String token;
  const ServiceManageScreen({super.key, required this.token});

  @override
  State<ServiceManageScreen> createState() => _ServiceManageScreenState();
}

class _ServiceManageScreenState extends State<ServiceManageScreen> {
  List<dynamic> services = [];
  bool isLoading = true;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    final res = await http.get(
      Uri.parse('$baseUrl/provider/services'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      setState(() {
        services = json.decode(res.body);
        isLoading = false;
      });
    }
  }

  Future<void> addService(String name, String description) async {
    final res = await http.post(
      Uri.parse('$baseUrl/provider/services'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'name': name, 'description': description}),
    );

    if (res.statusCode == 201) {
      fetchServices();
      _nameController.clear();
      _descController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm dịch vụ thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(json.decode(res.body)['message'] ?? 'Lỗi')),
      );
    }
  }

  Future<void> deleteService(String name) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/provider/services/$name'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200) {
      fetchServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xoá thành công')),
      );
    }
  }

  Future<void> updateDescription(String name, String description) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/provider/services/$name'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'description': description}),
    );

    if (res.statusCode == 200) {
      fetchServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật mô tả thành công')),
      );
    }
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final name = service['name'];
    final desc = service['description'] ?? '';

    final descCtrl = TextEditingController(text: desc);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả dịch vụ'),
              onSubmitted: (value) => updateDescription(name, value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => updateDescription(name, descCtrl.text),
                  child: const Text('Cập nhật'),
                ),
                TextButton(
                  onPressed: () => deleteService(name),
                  child: const Text('Xoá', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAddServiceForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Mô tả dịch vụ'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () =>
                addService(_nameController.text, _descController.text),
            child: const Text('Thêm dịch vụ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: fetchServices,
      child: ListView(
        children: [
          _buildAddServiceForm(),
          const Divider(),
          ...services.map((s) => _buildServiceCard(s)).toList(),
        ],
      ),
    );
  }
}
