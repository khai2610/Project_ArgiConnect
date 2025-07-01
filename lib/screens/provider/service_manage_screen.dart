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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Mô tả dịch vụ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => updateDescription(name, descCtrl.text),
                icon: const Icon(Icons.save),
                label: const Text('Cập nhật'),
              ),
              TextButton.icon(
                onPressed: () => deleteService(name),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Xoá', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddServiceForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thêm dịch vụ mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên dịch vụ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Mô tả dịch vụ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  addService(_nameController.text, _descController.text),
              icon: const Icon(Icons.add),
              label: const Text('Thêm dịch vụ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchServices,
              child: ListView(
                children: [
                  _buildAddServiceForm(),
                  ...services.map((s) => _buildServiceCard(s as Map<String, dynamic>)).toList(),
                ],
              ),
            ),
    );
  }
}
