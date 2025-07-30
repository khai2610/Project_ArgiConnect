import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'provider_detail_screen.dart';

class ServiceProvidersMapScreen extends StatefulWidget {
  final String token;
  final String farmerId;
  final String serviceType;

  const ServiceProvidersMapScreen({
    Key? key,
    required this.token,
    required this.farmerId,
    required this.serviceType,
  }) : super(key: key);

  @override
  State<ServiceProvidersMapScreen> createState() =>
      _ServiceProvidersMapScreenState();
}

class _ServiceProvidersMapScreenState extends State<ServiceProvidersMapScreen> {
  List<dynamic> providers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProvidersByService();
  }

  Future<void> fetchProvidersByService() async {
    final url = Uri.parse(publicProvidersUrl);
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final all = json.decode(res.body) as List;
        final filtered = all.where((p) {
          final services = p['services'] as List?;
          return services?.any((s) =>
                  (s['name'] as String?)?.toLowerCase().trim() ==
                  widget.serviceType.toLowerCase().trim()) ??
              false;
        }).toList();

        for (var p in filtered) {
          final ratingRes = await http.get(
            Uri.parse('$baseUrl/public/provider/${p['_id']}/ratings'),
          );
          if (ratingRes.statusCode == 200) {
            p['ratings'] = json.decode(ratingRes.body);
          }
        }

        setState(() {
          providers = filtered;
          isLoading = false;
        });
      } else {
        debugPrint('Lỗi khi fetch providers: ${res.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Lỗi fetchProvidersByService: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 16,
        );
      }),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final ratings = provider['ratings'] as List? ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDetailScreen(
              providerId: provider['_id']?.toString() ?? '',
              farmerId: widget.farmerId,
              token: widget.token,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: Text(provider['company_name']?.toString() ?? 'Không rõ'),
          subtitle: Text(provider['address']?.toString() ?? ''),
          children: [
            if (ratings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Chưa có đánh giá'),
              )
            else
              ...ratings.map((r) => ListTile(
                    title: _buildRatingStars(r['rating'] ?? 0),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r['comment'] != null &&
                            r['comment'].toString().isNotEmpty)
                          Text('Nhận xét: ${r['comment']}'),
                        if (r['crop_type'] != null)
                          Text('Cây trồng: ${r['crop_type']}'),
                        if (r['preferred_date'] != null)
                          Text(
                              'Ngày: ${r['preferred_date'].toString().split('T')[0]}'),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dịch vụ: ${widget.serviceType}'),
        backgroundColor: Colors.green.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : providers.isEmpty
              ? const Center(child: Text('Không có nhà cung cấp phù hợp'))
              : ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) =>
                      _buildProviderCard(providers[index]),
                ),
    );
  }
}
