import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class ApprovedProvidersScreen extends StatefulWidget {
  final String token;

  const ApprovedProvidersScreen({
    Key? key,
    required this.token,
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
    final url = Uri.parse(approvedProvidersUrl); // từ constants.dart

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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (providers.isEmpty) {
      return const Center(child: Text('Không có nhà cung cấp nào được duyệt'));
    }

    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(provider['company_name'] ?? 'Không tên'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${provider['email']}'),
                Text('SĐT: ${provider['phone']}'),
                if (provider['address'] != null)
                  Text('Địa chỉ: ${provider['address']}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
