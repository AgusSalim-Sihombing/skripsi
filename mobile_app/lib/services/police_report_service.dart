import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/config/api_config.dart';

class PoliceReportService {
  // ApiConfig.baseUrl diasumsikan sudah: http://IP:3001/api
  static const String _masyarakatBase = '/mobile/laporan-kepolisian';
  static const String _officerBase = '/mobile/officer/field-reports';

  static Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('user_token');
    if (t == null || t.isEmpty) throw Exception("TOKEN_MISSING");
    return t;
  }

  static Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  static String _url(String path) => "${ApiConfig.baseUrl}$path";

  static dynamic _safeJsonDecode(http.Response res) {
    try {
      return jsonDecode(res.body);
    } catch (_) {
      final snippet = res.body.length > 120
          ? res.body.substring(0, 120)
          : res.body;
      throw Exception("NON_JSON_RESPONSE(${res.statusCode}): $snippet");
    }
  }

  static dynamic _unwrapData(dynamic decoded) {
    if (decoded is Map && decoded['data'] != null) return decoded['data'];
    return decoded;
  }

  // ===========================
  //  MASYARAKAT
  // ===========================

  static Future<int> createReport(Map<String, dynamic> payload) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse(_url(_masyarakatBase)),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 201 || res.statusCode == 200) {
      final id = (decoded is Map ? decoded['id'] : null) ?? 0;
      return int.tryParse(id.toString()) ?? 0;
    }

    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal buat laporan (${res.statusCode})",
    );
  }

  static Future<List<Map<String, dynamic>>> fetchMine({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(_url("$_masyarakatBase/mine?page=$page&limit=$limit")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) {
      final data = _unwrapData(decoded);
      return List<Map<String, dynamic>>.from(
        (data as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal ambil mine (${res.statusCode})",
    );
  }

  static Future<Map<String, dynamic>> fetchMineDetail(int id) async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(_url("$_masyarakatBase/mine/$id")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) {
      final data = _unwrapData(decoded);
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal ambil detail (${res.statusCode})",
    );
  }

  // ===========================
  //  OFFICER
  // ===========================

  static Future<List<Map<String, dynamic>>> fetchPending({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(_url("$_officerBase/pending?page=$page&limit=$limit")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) {
      final data = _unwrapData(decoded);
      return List<Map<String, dynamic>>.from(
        (data as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal ambil pending (${res.statusCode})",
    );
  }

  static Future<List<Map<String, dynamic>>> fetchMineOfficer({
    String? status, // on_process / selesai
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _token();
    final q = status == null ? "" : "&status=$status";
    final res = await http.get(
      Uri.parse(_url("$_officerBase/mine?page=$page&limit=$limit$q")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) {
      final data = _unwrapData(decoded);
      return List<Map<String, dynamic>>.from(
        (data as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal ambil mine officer (${res.statusCode})",
    );
  }

  static Future<Map<String, dynamic>> fetchOfficerDetail(int id) async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(_url("$_officerBase/$id")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) {
      final data = _unwrapData(decoded);
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal ambil detail (${res.statusCode})",
    );
  }

  static Future<void> respond(int id) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse(_url("$_officerBase/$id/respond")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) return;
    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal respond (${res.statusCode})",
    );
  }

  static Future<void> finish(int id) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse(_url("$_officerBase/$id/finish")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) return;
    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal finish (${res.statusCode})",
    );
  }

  static Future<void> cancelMine(int id) async {
    final token = await _token();

    final res = await http.post(
      Uri.parse(_url("$_masyarakatBase/mine/$id/cancel")),
      headers: _headers(token),
    );

    final decoded = _safeJsonDecode(res);
    if (res.statusCode == 200) return;

    throw Exception(
      (decoded is Map ? decoded['message'] : null) ??
          "Gagal cancel (${res.statusCode})",
    );
  }
}
