import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/session.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // 🔁 Thay đổi URL thực tế

  /// Gửi GET request
  static Future<http.Response> get(String endpoint, {bool useAuth = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _buildHeaders(useAuth);
    return await http.get(url, headers: headers);
  }

  /// Gửi POST request với JSON body
  static Future<http.Response> post(String endpoint, Map<String, dynamic> data, {bool useAuth = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _buildHeaders(useAuth);
    return await http.post(url, headers: headers, body: jsonEncode(data));
  }

  /// Gửi PUT request (nếu bạn cần)
  static Future<http.Response> put(String endpoint, Map<String, dynamic> data, {bool useAuth = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _buildHeaders(useAuth);
    return await http.put(url, headers: headers, body: jsonEncode(data));
  }

  /// Gửi DELETE request (nếu bạn cần)
  static Future<http.Response> delete(String endpoint, {bool useAuth = false}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = _buildHeaders(useAuth);
    return await http.delete(url, headers: headers);
  }

  /// Tạo headers mặc định + Authorization nếu cần
  static Map<String, String> _buildHeaders(bool useAuth) {
    final headers = {'Content-Type': 'application/json'};

    if (useAuth && Session.authToken != null) {
      headers['Authorization'] = 'Bearer ${Session.authToken}';
    }

    return headers;
  }
}

