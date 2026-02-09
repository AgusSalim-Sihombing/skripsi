import 'package:flutter/material.dart';
import 'package:mobile_app/pages/landing_page.dart';
import 'package:mobile_app/pages/officer/officer_home_page.dart';
import 'package:mobile_app/pages/register_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // TimeoutException
import 'dart:io'; // SocketException
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/config/api_config.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/background_zone_service.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // SAMAKAN IP DENGAN REGISTER
  // final String apiUrl = 'http://10.121.204.17:3000/api/users/login';
  // final String apiUrl = 'http://192.168.115.17:3000/api/users/login';

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ====== IZIN LOKASI SAAT LOGIN ======
  bool _locationCheckedOnce = false;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack(
        'Location service belum aktif. Aktifkan GPS untuk gunakan fitur maps.',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack(
          'Izin lokasi ditolak. Beberapa fitur (seperti Maps Lokasi Kejahatan) mungkin tidak berfungsi optimal.',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack(
        'Izin lokasi diblokir permanen. Buka Pengaturan > Aplikasi dan izinkan lokasi untuk aplikasi ini.',
      );
      return false;
    }

    return true;
  }

  Future<void> _ensureLocationOnLogin() async {
    if (_locationCheckedOnce) return;
    _locationCheckedOnce = true;

    await _handleLocationPermission();
    // Kalau user nolak, login tetap boleh jalan.
  }

  Future<bool> _forceLocationForOfficer() async {
    // GPS wajib ON
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack(
        "GPS belum aktif. Aktifkan dulu biar officer bisa menerima dispatch.",
      );
      await Geolocator.openLocationSettings();
      return false;
    }

    // permission wajib allow
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showSnack("Izin lokasi wajib diizinkan untuk akun officer.");
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack(
        "Izin lokasi diblokir permanen. Buka Pengaturan dan izinkan lokasi.",
      );
      await Geolocator.openAppSettings();
      return false;
    }

    // test ambil lokasi sekali (biar beneran valid)
    try {
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return true;
    } catch (_) {
      _showSnack("Gagal ambil lokasi. Coba aktifkan GPS dan ulangi.");
      return false;
    }
  }

  // ========== LOGIN ==========
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack("Username dan password wajib diisi");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _ensureLocationOnLogin();

      await NotificationService.init(requestPermission: true);
      await NotificationService.requestPermissionIfNeeded();

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic>? result;
      try {
        result = jsonDecode(response.body);
      } catch (_) {
        result = null;
      }

      if (response.statusCode == 200) {
        final user = result?['user'] as Map<String, dynamic>?;
        final token = result?['token'] as String?;

        if (user == null || token == null) {
          _showSnack(
            "Login berhasil, tapi data user/token tidak lengkap dari server",
          );
          return;
        }

        // ambil role & status_verifikasi dari response
        final String role = (user['role'] ?? 'masyarakat').toString();
        final String statusVerif = (user['status_verifikasi'] ?? 'pending')
            .toString();

        // officer dianggap approved kalau role=officer & status_verifikasi=verified
        final bool isOfficerApproved =
            role == 'officer' && statusVerif == 'verified';

        // Simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', token);
        await prefs.setInt('user_id', user['id'] as int);
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setString('user_role', role);
        await prefs.setString('status_verifikasi', statusVerif);
        await prefs.setBool('is_officer_approved', isOfficerApproved);
        await prefs.setString('user_token', token);
        final displayName = user['username'] ?? user['nama'] ?? username;

        _showSnack("Login berhasil, selamat datang $displayName");

        final String tokenStr =
            token; // token sudah pasti tidak null karena sudah dicek
        final String socketBaseUrl = ApiConfig.baseUrl.endsWith("/api")
            ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 4)
            : ApiConfig.baseUrl;

        try {
          await BackgroundZoneService.init();
          await BackgroundZoneService.syncDataFromApi(token);
          await BackgroundZoneService.restartHard();
        } catch (e) {
          debugPrint("Gagal start background service: $e");
        }

        // ====== ROUTING SESUAI ROLE ======
        if (role == 'officer') {
          if (!isOfficerApproved) {
            _showSnack(
              "Akun kamu terdaftar sebagai OFFICER, tapi masih menunggu verifikasi admin.",
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LandingPage(
                  username: displayName,
                  token: tokenStr,
                  baseUrl: socketBaseUrl,
                ),
              ),
            );
          } else {
            final ok = await _forceLocationForOfficer();
            if (!ok) return;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OfficerHomePage(
                  username: displayName,
                  token: tokenStr,
                  baseUrl: socketBaseUrl,
                ),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LandingPage(
                username: displayName,
                token: tokenStr,
                baseUrl: socketBaseUrl,
              ),
            ),
          );
        }
      }
    } on TimeoutException {
      _showSnack(
        "Waktu koneksi habis. Server lama merespon, coba lagi sebentar lagi.",
      );
    } on SocketException {
      _showSnack(
        "Tidak bisa terhubung ke server. Pastikan koneksi internet & IP backend sudah benar.",
      );
    } catch (e) {
      _showSnack("Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 150, width: 150),
              const SizedBox(height: 20),

              // Card putih di tengah
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Username
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline),
                        hintText: 'Username',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        // nanti bisa diarahkan ke halaman lupa password
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "LOGIN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tombol Signup
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "SIGNUP",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
