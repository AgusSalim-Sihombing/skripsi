import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kRole = 'role'; // "masyarakat" | "officer"

  static const String _kBgEnabled = 'bg_enabled'; // bool (prefs)

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await _secure.write(key: _kAccessToken, value: accessToken);
    await _secure.write(key: _kRefreshToken, value: refreshToken);
    await _secure.write(key: _kRole, value: role);
  }

  Future<String?> getAccessToken() => _secure.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _secure.read(key: _kRefreshToken);
  Future<String?> getRole() => _secure.read(key: _kRole);

  Future<void> clearSession() async {
    await _secure.delete(key: _kAccessToken);
    await _secure.delete(key: _kRefreshToken);
    await _secure.delete(key: _kRole);
  }

  Future<void> setBgEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBgEnabled, value);
  }

  Future<bool> getBgEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBgEnabled) ?? false;
  }
}
