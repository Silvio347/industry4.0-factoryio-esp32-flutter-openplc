import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://SEU_BACKEND_LOCAL:8000';

  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );
  }

  static Future<http.Response> put(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.put(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );
  }

  static Future<http.Response> delete(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.delete(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );
  }
} 
