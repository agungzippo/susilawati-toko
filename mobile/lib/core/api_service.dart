import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String? _token;

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 maps to host machine localhost in Android Emulator
        return 'http://10.0.2.2:3000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['token'] != null) {
      _token = data['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', jsonEncode(data['user']));
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login gagal, periksa email dan kata sandi');
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_data');
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  // Dashboard summary
  Future<Map<String, dynamic>> getSummary() async {
    final url = Uri.parse('$baseUrl/inventory/summary');
    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    }
    throw Exception('Gagal memuat ringkasan stok');
  }

  // Alerts
  Future<Map<String, dynamic>> getAlerts() async {
    final url = Uri.parse('$baseUrl/inventory/alerts');
    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    }
    throw Exception('Gagal memuat data peringatan stok');
  }

  // Products list
  Future<List<dynamic>> getProducts({String? search, String? categoryId}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty) queryParams['categoryId'] = categoryId;

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as List<dynamic>;
    }
    throw Exception('Gagal memuat daftar produk');
  }

  // Barcode lookup
  Future<Map<String, dynamic>?> getVariantByBarcode(String barcode) async {
    final url = Uri.parse('$baseUrl/products/variants/by-barcode/$barcode');
    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Gagal mencari barcode');
  }

  // Invoices list
  Future<List<dynamic>> getInvoices({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    final uri = Uri.parse('$baseUrl/invoices').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as List<dynamic>;
    }
    throw Exception('Gagal memuat daftar faktur');
  }

  // Incoming schedules list
  Future<List<dynamic>> getSchedules({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    final uri = Uri.parse('$baseUrl/receipts/schedules').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as List<dynamic>;
    }
    throw Exception('Gagal memuat jadwal kedatangan barang');
  }

  // Trigger Vision AI extraction
  Future<Map<String, dynamic>> extractInvoice(String invoiceId) async {
    final url = Uri.parse('$baseUrl/invoices/$invoiceId/extract');
    final response = await http.post(url, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    }
    throw Exception('Gagal mengekstrak faktur');
  }

  // Confirm goods receipt
  Future<Map<String, dynamic>> confirmReceipt(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/receipts/confirm');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'Gagal mengonfirmasi penerimaan barang');
  }

  // Recent transactions (Screen 2)
  Future<List<dynamic>> getRecentTransactions({int limit = 10}) async {
    final url = Uri.parse('$baseUrl/inventory/recent-transactions?limit=$limit');
    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as List<dynamic>;
    }
    return [];
  }

  // Suppliers list (Screen 8)
  Future<List<dynamic>> getSuppliers() async {
    final url = Uri.parse('$baseUrl/suppliers');
    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] as List<dynamic>;
    }
    return [];
  }

  // Stock out / sales (Screen 7)
  Future<Map<String, dynamic>> stockOut(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/inventory/stock-out');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'] as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? 'Gagal mencatat barang keluar');
  }
}
