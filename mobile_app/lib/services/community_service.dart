import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/config/api_config.dart';

class CommunityService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> authHeaderOnly() async {
    final token = await _getToken();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  static String _base(String path) => '${ApiConfig.baseUrl}$path';

  // ===========================
  // LOBBY LIST
  // GET /api/public/communities
  // ===========================
  static Future<List<dynamic>> fetchCommunities({
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      _base(
        '/public/communities?search=${Uri.encodeQueryComponent(search)}&page=$page&limit=$limit',
      ),
    );

    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil komunitas: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body);
    return (json['data'] as List<dynamic>);
  }

  // ===========================
  // SEARCH USERNAME
  // GET /api/public/users/search?username=...
  // ===========================
  static Future<List<dynamic>> searchUsers(String username) async {
    final uri = Uri.parse(
      _base(
        '/public/users/search?username=${Uri.encodeQueryComponent(username)}',
      ),
    );

    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Gagal search user: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as List<dynamic>);
  }

  // ===========================
  // CREATE COMMUNITY (multipart)
  // POST /api/public/communities
  // fields: name, members (JSON string)
  // file: icon
  // ===========================
  static Future<int> createCommunity({
    required String name,
    required List<String> memberUsernames,
    File? iconFile,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(_base('/public/communities'));

    final req = http.MultipartRequest('POST', uri);

    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    req.fields['name'] = name.trim();
    req.fields['members'] = jsonEncode(memberUsernames);

    if (iconFile != null) {
      final bytes = await iconFile.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes(
          'icon',
          bytes,
          filename: iconFile.path.split('/').last,
        ),
      );
    }

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 201) {
      throw Exception('Gagal create komunitas: ${streamed.statusCode} $body');
    }

    final json = jsonDecode(body);
    return (json['communityId'] as int);
  }

  // ===========================
  // JOIN REQUEST
  // POST /api/public/communities/:id/join-request
  // ===========================
  static Future<void> requestJoin(int communityId) async {
    final uri = Uri.parse(
      _base('/public/communities/$communityId/join-request'),
    );
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Gagal join request: ${res.statusCode} ${res.body}');
    }
  }

  // ===========================
  // INVITE ACCEPT/DECLINE
  // ===========================
  static Future<void> acceptInvite(int communityId) async {
    final uri = Uri.parse(
      _base('/public/communities/$communityId/invite/accept'),
    );
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Gagal accept invite: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> declineInvite(int communityId) async {
    final uri = Uri.parse(
      _base('/public/communities/$communityId/invite/decline'),
    );
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Gagal decline invite: ${res.statusCode} ${res.body}');
    }
  }

  // ===========================
  // GET MESSAGES
  // GET /api/public/communities/:id/messages?limit=50&before=...
  // ===========================
  static Future<List<dynamic>> fetchMessages({
    required int communityId,
    int limit = 50,
    String? beforeIso,
  }) async {
    final q = <String, String>{'limit': '$limit'};
    if (beforeIso != null) q['before'] = beforeIso;

    final uri = Uri.parse(
      _base('/public/communities/$communityId/messages'),
    ).replace(queryParameters: q);

    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Gagal ambil chat: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as List<dynamic>);
  }

  // ===========================
  // SEND MESSAGE
  // POST /api/public/communities/:id/messages
  // ===========================
  static Future<void> sendMessage({
    required int communityId,
    required String message,
  }) async {
    final uri = Uri.parse(_base('/public/communities/$communityId/messages'));

    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );

    if (res.statusCode != 201) {
      throw Exception('Gagal kirim pesan: ${res.statusCode} ${res.body}');
    }
  }

  // ===========================
  // OWNER: LIST JOIN REQUESTS
  // GET /api/public/communities/:id/requests
  // ===========================
  static Future<List<dynamic>> fetchJoinRequests(int communityId) async {
    final uri = Uri.parse(_base('/public/communities/$communityId/requests'));
    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 403) {
      // bukan owner
      throw Exception('FORBIDDEN_OWNER');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal ambil join requests: ${res.statusCode} ${res.body}',
      );
    }

    return (jsonDecode(res.body) as List<dynamic>);
  }

  // ===========================
  // OWNER: APPROVE/REJECT
  // PATCH /api/public/communities/:id/requests/:userId
  // ===========================
  static Future<void> respondJoinRequest({
    required int communityId,
    required int userId,
    required String action, // approve/reject
  }) async {
    final uri = Uri.parse(
      _base('/public/communities/$communityId/requests/$userId'),
    );

    final res = await http.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode({'action': action}),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal respond request: ${res.statusCode} ${res.body}');
    }
  }
}
