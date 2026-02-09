import 'dart:convert';
import 'dart:io';
// import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/config/api_config.dart';

class ProfileService {
  static Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('user_token');
    if (t == null || t.isEmpty) throw Exception("TOKEN_MISSING");
    return t;
  }

  static Map<String, String> _headersJson(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  static Map<String, String> _headersAuth(String token) => {
    "Authorization": "Bearer $token",
  };

  static dynamic _unwrap(dynamic decoded) {
    if (decoded is Map && decoded['data'] != null) return decoded['data'];
    return decoded;
  }

  static String _url(String path) => "${ApiConfig.baseUrl}$path";

  // =========================
  // GET ME
  // =========================
  static Future<Map<String, dynamic>> getMe() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(_url("/mobile/me")),
      headers: _headersAuth(token),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }

    if (res.statusCode == 200) {
      final data = _unwrap(decoded);
      return Map<String, dynamic>.from(data);
    }

    final msg =
        (decoded is Map ? decoded['message'] : null) ??
        "Gagal ambil profil (${res.statusCode})";
    throw Exception(msg);
  }

  // =========================
  // UPDATE ME
  // =========================
  static Future<Map<String, dynamic>> updateMe(
    Map<String, dynamic> payload,
  ) async {
    final token = await _token();

    final res = await http.put(
      Uri.parse(_url("/mobile/me")),
      headers: _headersJson(token),
      body: jsonEncode(payload),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }

    if (res.statusCode == 200) {
      final data = _unwrap(decoded);
      return Map<String, dynamic>.from(data);
    }

    final msg =
        (decoded is Map ? decoded['message'] : null) ??
        "Gagal update profil (${res.statusCode})";
    throw Exception(msg);
  }

  // =========================
  // RESUBMIT KTP (REJECTED)
  // =========================
  static Future<Map<String, dynamic>> resubmitKtp(File file) async {
    final token = await _token();

    final req = http.MultipartRequest(
      "POST",
      Uri.parse(_url("/mobile/me/ktp")),
    );
    req.headers.addAll(_headersAuth(token));

    req.files.add(await http.MultipartFile.fromPath("ktp_image", file.path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = null;
    }

    if (streamed.statusCode == 200) {
      final data = _unwrap(decoded);
      return Map<String, dynamic>.from(data);
    }

    final msg =
        (decoded is Map ? decoded['message'] : null) ??
        "Gagal kirim ulang KTP (${streamed.statusCode})";
    throw Exception(msg);
  }

  // =========================
  // GET KTP BYTES (preview)
  // =========================
  static Future<List<int>> getMyKtpBytes() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse(_url("/mobile/me/ktp")),
      headers: _headersAuth(token),
    );

    if (res.statusCode == 200) {
      return res.bodyBytes;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }

    final msg =
        (decoded is Map ? decoded['message'] : null) ??
        "Gagal ambil KTP (${res.statusCode})";
    throw Exception(msg);
  }
}
