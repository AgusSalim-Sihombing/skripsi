import 'package:flutter/material.dart';
import 'package:mobile_app/pages/landing_page.dart';
import 'package:mobile_app/pages/officer/officer_home_page.dart';
import 'package:mobile_app/pages/register_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // TimeoutException
import 'dart:io'; // SocketException
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/widgets/floating_theme_mode_widget.dart';
import 'package:mobile_app/widgets/message_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/config/api_config.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/background_zone_service.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/theme/theme_controller.dart';

enum AppPopupType { success, error, info, warning }

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Offset _themeFabOffset = Offset.zero;
  bool _themeFabReady = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  OverlayEntry? _activePopupEntry;

  // SAMAKAN IP DENGAN REGISTER YA GES
  // final String apiUrl = 'http://10.121.204.17:3000/api/users/login';
  // final String apiUrl = 'http://192.168.115.17:3000/api/users/login';
  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: isDark ? AppColors.textMuted : Colors.grey.shade700,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.textMuted2 : Colors.grey.shade600,
      ),
      filled: true,
      fillColor: isDark ? AppColors.white05 : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderLight2 : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isDark ? AppColors.primaryBlue : Colors.deepPurple,
          width: 1.2,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  // void _showSnack(String message) {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(SnackBar(content: Text(message)));
  // }

  // void _showErrorDialog(String message) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Login Gagal"),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("OK"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _showPopupCard(
    String message, {
    required AppPopupType type,
    Duration duration = const Duration(seconds: 2),
  }) async {
    if (!mounted) return;

    _activePopupEntry?.remove();
    _activePopupEntry = null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color bgColor;
    late final Color borderColor;
    late final Color iconBgColor;
    late final Color textColor;
    late final IconData icon;
    late final String title;

    switch (type) {
      case AppPopupType.success:
        bgColor = isDark ? const Color(0xFF0F2A1B) : const Color(0xFFEAFBF1);
        borderColor = isDark
            ? const Color(0xFF1F7A45)
            : const Color(0xFF79D9A2);
        iconBgColor = const Color(0xFF22C55E);
        textColor = isDark ? Colors.white : const Color(0xFF14532D);
        icon = Icons.check_circle_rounded;
        title = "Berhasil";
        break;

      case AppPopupType.error:
        bgColor = isDark ? const Color(0xFF2A1010) : const Color(0xFFFDEDED);
        borderColor = isDark
            ? const Color(0xFFB91C1C)
            : const Color(0xFFF5A3A3);
        iconBgColor = const Color(0xFFEF4444);
        textColor = isDark ? Colors.white : const Color(0xFF7F1D1D);
        icon = Icons.error_rounded;
        title = "Error";
        break;

      case AppPopupType.warning:
        bgColor = isDark ? const Color(0xFF2B1E0D) : const Color(0xFFFFF6E8);
        borderColor = isDark
            ? const Color(0xFFD97706)
            : const Color(0xFFF7C97B);
        iconBgColor = const Color(0xFFF59E0B);
        textColor = isDark ? Colors.white : const Color(0xFF92400E);
        icon = Icons.warning_amber_rounded;
        title = "Peringatan";
        break;

      case AppPopupType.info:
        bgColor = isDark ? const Color(0xFF0E1B35) : const Color(0xFFEFF6FF);
        borderColor = isDark
            ? const Color(0xFF3B82F6)
            : const Color(0xFF93C5FD);
        iconBgColor = const Color(0xFF3B82F6);
        textColor = isDark ? Colors.white : const Color(0xFF1E3A8A);
        icon = Icons.info_rounded;
        title = "Informasi";
        break;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    final entry = OverlayEntry(
      builder: (context) {
        final topInset = MediaQuery.of(context).padding.top + 12;

        return Positioned(
          top: topInset,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -20, end: 0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final opacity = ((20 - value.abs()) / 20).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.34 : 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: TextStyle(
                                  color: textColor.withOpacity(0.95),
                                  fontSize: 13.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    _activePopupEntry = entry;

    await Future.delayed(duration);

    if (_activePopupEntry == entry) {
      entry.remove();
      _activePopupEntry = null;
    }
  }

  Future<void> _showSuccess(String message) async {
    await _showPopupCard(message, type: AppPopupType.success);
  }

  Future<void> _showError(String message) async {
    await _showPopupCard(message, type: AppPopupType.error);
  }

  Future<void> _showInfo(String message) async {
    await _showPopupCard(message, type: AppPopupType.info);
  }

  Future<void> _showWarning(String message) async {
    await _showPopupCard(message, type: AppPopupType.warning);
  }

  // ====== IZIN LOKASI SAAT LOGIN ======
  bool _locationCheckedOnce = false;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showWarning(
        'Location service belum aktif. Aktifkan GPS untuk gunakan fitur maps.',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showWarning(
          'Izin lokasi ditolak. Beberapa fitur (seperti Maps Lokasi Kejahatan) mungkin tidak berfungsi optimal.',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showWarning(
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
      _showWarning(
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
      _showWarning("Izin lokasi wajib diizinkan untuk akun officer.");
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showWarning(
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
      _showWarning("Gagal ambil lokasi. Coba aktifkan GPS dan ulangi.");
      return false;
    }
  }

  Widget _buildThemeFloatingButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return Positioned(
          top: 18,
          right: 18,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: ThemeController.toggleTheme,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.surfaceGlass.withOpacity(0.92)
                      : Colors.white.withOpacity(0.95),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderLight2
                        : Colors.black.withOpacity(0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.shadowDark.withOpacity(0.35)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? AppColors.accentLight : AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration2({
    required BuildContext context,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: isDark ? AppColors.textMuted : Colors.grey.shade700,
      ),
      hintText: hint,
      filled: true,
      fillColor: isDark ? AppColors.white05 : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderLight2 : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
          color: isDark ? AppColors.primaryBlue : Colors.deepPurple,
          width: 1.2,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  // ========== LOGIN ==========
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError("Username dan password wajib diisi");
      Text(
        "Username dan password wajib diisi",
        style: TextStyle(color: const Color.fromARGB(255, 255, 0, 0)),
      );
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
          _showSuccess(
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

        // _showSuccess("Login berhasil, selamat datang $displayName");
        MessagePopup.success(
          context,
          "Login berhasil, selamat datang $displayName",
        );

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
            _showInfo(
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
      } else if (response.statusCode == 401) {
        _showError("Username atau password salah ");
      } else if (response.statusCode == 400) {
        _showError(result?['message'] ?? "Data login tidak valid");
      } else {
        _showError(
          result?['message'] ??
              "Login gagal. Status code: ${response.statusCode}",
        );
      }
    } on TimeoutException {
      _showError(
        "Waktu koneksi habis. Server lama merespon, coba lagi sebentar lagi.",
      );
    } on SocketException {
      _showError(
        "Tidak bisa terhubung ke server. Pastikan koneksi internet & IP backend sudah benar.",
      );
    } catch (e) {
      _showError("Terjadi kesalahan: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _activePopupEntry?.remove();
    _activePopupEntry = null;
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppGradients.background
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF7F9FF), Color(0xFFFFFFFF)],
                    ),
            ),
          ),

          if (isDark) ...[
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPurple.withOpacity(0.14),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withOpacity(0.12),
                ),
              ),
            ),
          ],

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isDark
                      ? Image.asset('assets/logo3.png', width: 120)
                      : Image.asset('assets/logo.png', width: 120),
                  const SizedBox(height: 20),

                  Container(
                    width: 420,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 25,
                    ),
                    decoration: BoxDecoration(
                      // color: isDark
                      //     ? AppColors.surfaceGlass.withValues(alpha: 0.95)
                      //     : Colors.white,
                      gradient: isDark
                          ? AppGradients.background
                          : const LinearGradient(
                              colors: [Colors.white, Color(0xFFF7F9FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderLight2
                            : const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ).withValues(alpha: 0.95),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? AppColors.glowBlue
                              : Colors.grey.withValues(alpha: 0.90),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Login ke SIGAP",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),

                        TextField(
                          controller: _usernameController,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimary
                                : Colors.black87,
                          ),
                          decoration: _inputDecoration(
                            context: context,
                            hint: 'Username',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimary
                                : Colors.black87,
                          ),
                          decoration: _inputDecoration(
                            context: context,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: isDark
                                    ? AppColors.textMuted
                                    : Colors.grey.shade700,
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
                          onPressed: () {},
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textMuted2
                                  : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? AppGradients.loginButton
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5A24),
                                        Color(0xFF4E342E),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: cs.primary,
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
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
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            "SIGNUP",
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.accentLight
                                  : cs.primary,
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
          const FloatingThemeModeWidget(),
        ],
      ),
    );
  }
}
