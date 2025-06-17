import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/session.dart';

class ApiService {
  static const String baseUrl =
      'http://<your-backend>'; // Thay bằng backend của bạn

  static Future<http.Response> get(String endpoint,
      {bool useAuth = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _buildHeaders(useAuth);
    return http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data,
      {bool useAuth = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _buildHeaders(useAuth);
    return http.post(url, headers: headers, body: jsonEncode(data));
  }

  static Map<String, String> _buildHeaders(bool useAuth) {
    final headers = {'Content-Type': 'application/json'};
    if (useAuth && Session.authToken != null) {
      headers['Authorization'] = 'Bearer ${Session.authToken}';
    }
    return headers;
  }
}
