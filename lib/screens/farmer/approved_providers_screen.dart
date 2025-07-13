import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'provider_detail_screen.dart';

class ApprovedProvidersScreen extends StatefulWidget {
  final String token;
  final String farmerId;

  const ApprovedProvidersScreen({
    Key? key,
    required this.token,
    required this.farmerId,
  }) : super(key: key);

  @override
  State<ApprovedProvidersScreen> createState() =>
      _ApprovedProvidersScreenState();
}

class _ApprovedProvidersScreenState extends State<ApprovedProvidersScreen> {
  List<dynamic> providers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    final url = Uri.parse(approvedProvidersUrl);

    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        setState(() {
          providers = json.decode(res.body);
          isLoading = false;
        });
      } else {
        debugPrint('Lỗi: ${res.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Nhà cung cấp đã duyệt'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : providers.isEmpty
              ? const Center(
                  child: Text('Không có nhà cung cấp nào được duyệt'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          provider['company_name'] ?? 'Không tên',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Email: ${provider['email']}'),
                            Text('SĐT: ${provider['phone']}'),
                            if (provider['address'] != null)
                              Text('Địa chỉ: ${provider['address']}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderDetailScreen(
                                providerId: provider['_id'],
                                farmerId: widget.farmerId,
                                token: widget.token,
                              ),
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
