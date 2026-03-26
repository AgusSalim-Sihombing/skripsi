import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/api_config.dart';
import 'package:mobile_app/pages/community/community_lobby_page.dart';
import 'package:mobile_app/pages/lapor_cepat.dart/daftar_laporan_cepat.dart';
import 'package:mobile_app/pages/lapor_cepat.dart/laporan_cepat.dart';
import 'package:mobile_app/pages/laporan_kepolisian/buat_laporan_kepolisian_page.dart';
import 'package:mobile_app/pages/laporan_kepolisian/daftar_laporan_kepolisian_page.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/maps_lokasi_kejahatan/maps_lokasi_kejahatan.dart';
import 'package:mobile_app/pages/profile_page.dart';
import 'package:mobile_app/pages/rekap_kriminal/rekap_kriminal_page.dart';
import 'package:mobile_app/pages/tentang/tentang_aplikasi.dart';
import 'package:mobile_app/services/background_zone_service.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/theme/theme_controller.dart';
import 'package:mobile_app/widgets/message_popup.dart';
import 'package:mobile_app/widgets/panic_hold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  final String username;
  final String token;
  final String baseUrl;

  const LandingPage({
    super.key,
    required this.username,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final SocketService _socket = SocketService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _pingTimer;

  String _role = '';
  String _statusVerif = 'pending';
  bool _isEligibleCommunity = false;

  Offset _themeFabOffset = Offset.zero;
  bool _themeFabReady = false;

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true; // Format bukan JWT

      // Decode payload
      final String normalized = base64Url.normalize(parts[1]);
      final String payloadString = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = jsonDecode(payloadString);

      if (!payloadMap.containsKey('exp')) return false;

      // Cek apakah waktu saat ini sudah melewati waktu 'exp'
      final exp = payloadMap['exp'];
      final expireDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

      return DateTime.now().isAfter(expireDate);
    } catch (e) {
      return true; // Jika terjadi error saat decode, anggap expired untuk keamanan
    }
  }

  Future<void> _handleExpiredSession() async {
    // Tampilkan notifikasi
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sesi login berakhir. Silahkan login ulang."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      // Hentikan service
      await BackgroundZoneService.stop();
      _socket.disconnect();

      // Bersihkan sesi lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      // Arahkan kembali ke LoginScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("❌ Gagal menangani expired session: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    if (_isTokenExpired(widget.token)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleExpiredSession();
      });
      return; // Stop inisialisasi lain jika token sudah mati
    }
    final svc = FlutterBackgroundService();

    svc.on('bg:log').listen((event) {
      final msg = event?['msg'];
      if (msg != null) debugPrint("🟣 $msg");
    });

    svc.on('bg:loc').listen((event) {
      if (event == null) return;
      debugPrint(
        "🟢 [UI] BG LOC lat=${event['lat']} lng=${event['lng']} acc=${event['acc']} ts=${event['ts']}",
      );
    });

    svc.on('bg:pong').listen((event) {
      debugPrint("✅ [UI] PONG from BG ts=${event?['ts']}");
    });

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final running = await svc.isRunning();
      debugPrint("🧪 [UI] ping... running=$running");
      svc.invoke('ping');
    });

    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    _socket.on("panic:responded", (payload) {
      final data = Map<String, dynamic>.from(payload);
      final officer = Map<String, dynamic>.from(data["officer"]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sudah direspon oleh officer: ${officer['nama']}"),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootZoneMonitor();
    });

    _loadEligibility();
  }

  bool get _isVerified => _statusVerif == 'verified';

  Future<void> _loadEligibility() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    final verif = prefs.getString('status_verifikasi') ?? 'pending';

    if (!mounted) return;
    setState(() {
      _role = role;
      _statusVerif = verif;
      _isEligibleCommunity = (role == 'masyarakat' && verif == 'verified');
    });
  }

  void _openCommunity() {
    if (_isEligibleCommunity) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommunityLobbyPage()),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Komunitas terkunci 🔒"),
        content: Text(
          "Fitur Komunitas cuma buat akun masyarakat yang sudah VERIFIED.\n\n"
          "Status kamu sekarang: $_statusVerif",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Oke"),
          ),
        ],
      ),
    );
  }

  void _guardVerified(String featureName, VoidCallback onAllowed) {
    if (_isVerified) {
      onAllowed();
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$featureName terkunci 🔒"),
        content: Text(
          "Fitur ini cuma bisa dipakai kalau akun kamu sudah VERIFIED.\n\n"
          "Status kamu sekarang: $_statusVerif\n\n"
          "Kalau status REJECTED, cek catatan admin & upload ulang KTP di Profil ya.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Oke"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: const Text("Buka Profil"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Keluar?"),
        content: const Text("Kamu yakin mau logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await BackgroundZoneService.stop();
      await Future.delayed(const Duration(milliseconds: 600));

      _socket.disconnect();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      MessagePopup.success(context, "Logout Berhasil");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("❌ logout error: $e");
      MessagePopup.error(context, "Logout Error");
    }
  }

  Future<void> _bootZoneMonitor() async {
    try {
      debugPrint("🟡 [UI] boot zone monitor...");

      await NotificationService.init();
      await BackgroundZoneService.init();

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        debugPrint("[UI] GPS mati");
        return;
      }

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        debugPrint("[UI] izin lokasi belum ada (harusnya udah di login)");
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 401) {
        debugPrint("[UI] Token expired terdeteksi dari API");
        _handleExpiredSession();
        return;
      }

      if (res.statusCode != 200) {
        debugPrint("[UI] fetch zona gagal: ${res.statusCode} ${res.body}");
        return;
      }

      final decoded = jsonDecode(res.body);
      final List data = decoded['data'] as List;

      final zones = data.map((e) => Map<String, dynamic>.from(e)).toList();
      await BackgroundZoneService.saveZones(zones);

      debugPrint("✅ [UI] BG zones saved: ${zones.length}");

      final svc = FlutterBackgroundService();
      final running = await svc.isRunning();

      if (running) {
        debugPrint("🟠 [UI] BG is running -> stopping...");
        await BackgroundZoneService.stop();
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      await BackgroundZoneService.start();
      debugPrint("✅ [UI] BG service started (fresh)");
    } catch (e) {
      debugPrint("❌ [UI] _bootZoneMonitor error: $e");
    }
  }

  double _toDoubleSafe(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _setupZonaBahayaMonitoring() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 401) {
        debugPrint("[UI] Token expired terdeteksi dari API");
        _handleExpiredSession();
        return;
      }

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] as List;

        final zones = data.map<Map<String, dynamic>>((z) {
          return {
            "id": int.tryParse(z["id_zona"].toString()) ?? 0,
            "nama": (z["nama_zona"] ?? "Zona Rawan").toString(),
            "lat": _toDoubleSafe(z["latitude"]),
            "lng": _toDoubleSafe(z["longitude"]),
            "radiusMeter": _toDoubleSafe(z["radius_meter"] ?? 300),
            "status": (z["status_zona"] ?? "pending").toString().toLowerCase(),
          };
        }).toList();

        await BackgroundZoneService.saveZones(zones);
        debugPrint("✅ BG zones saved: ${zones.length}");
      } else {
        debugPrint("❌ fetch zona gagal: ${res.statusCode} ${res.body}");
      }

      await BackgroundZoneService.restartHard();
      debugPrint("✅ [UI] BG service restarted hard");
    } catch (e) {
      debugPrint("❌ _setupZonaBahayaMonitoring error: $e");
    }
  }

  Widget _buildDraggableThemeButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    const double btnSize = 56;

    final double safeTop = media.padding.top + 10;
    final double minX = 8;
    final double minY = safeTop;
    final double maxX = media.size.width - btnSize - 8;
    final double maxY = media.size.height - btnSize - 8;

    if (!_themeFabReady) {
      _themeFabOffset = Offset(maxX, safeTop);
      _themeFabReady = true;
    }

    _themeFabOffset = Offset(
      _themeFabOffset.dx.clamp(minX, maxX),
      _themeFabOffset.dy.clamp(minY, maxY),
    );

    return Positioned(
      left: _themeFabOffset.dx,
      top: _themeFabOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _themeFabOffset = Offset(
              (_themeFabOffset.dx + details.delta.dx).clamp(minX, maxX),
              (_themeFabOffset.dy + details.delta.dy).clamp(minY, maxY),
            );
          });
        },
        onTap: () async {
          await ThemeController.toggleTheme();
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.surfaceGlass.withOpacity(0.95)
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
                      : Colors.black.withOpacity(0.12),
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
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featureItems = [
      _FeatureItem(
        title: "Maps Lokasi Kejahatan",
        icon: Icons.map_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrimeMapPage()),
          );
        },
      ),
      _FeatureItem(
        title: "Lapor Cepat",
        icon: Icons.flash_on_outlined,
        enabled: _isVerified,
        onTap: () => _guardVerified("Lapor Cepat", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaporCepatPage()),
          );
        }),
      ),
      _FeatureItem(
        title: "Daftar Laporan Cepat",
        icon: Icons.bolt_outlined,
        enabled: _isVerified,
        onTap: () => _guardVerified("Daftar Laporan Cepat", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DaftarLaporanPage()),
          );
        }),
      ),
      _FeatureItem(
        title: "Rekapan Kriminal",
        icon: Icons.list_alt_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RekapKriminalPage()),
          );
        },
      ),
      _FeatureItem(
        title: "Buat Laporan Kepolisian",
        icon: Icons.note_add_outlined,
        enabled: _isVerified,
        onTap: () => _guardVerified("Buat Laporan Kepolisian", () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BuatLaporanKepolisianPage(),
            ),
          );
        }),
      ),
      _FeatureItem(
        title: "Komunitas",
        icon: Icons.chat_bubble_outline,
        enabled: _isVerified,
        onTap: () => _guardVerified("Komunitas", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityLobbyPage()),
          );
        }),
      ),
      _FeatureItem(
        title: "Tentang Aplikasi",
        icon: Icons.info_outline,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TentangAplikasiPage()),
          );
        },
      ),
    ];

    // final pageController = PageController(viewportFraction: 0.92);
    // 0.85 berarti item utama mengambil 85% lebar layar, sisanya untuk item kiri/kanan
    final PageController pageController = PageController(
      viewportFraction: 0.85,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> carouselItems = [
      _TopInfoCard(
        title: "APLIKASI SIGAP SIAP MEMBANTU ANDA",
        subtitle: "Tindak lanjuti segala bentuk kriminal dengan cepat",
        image: "assets/phone2.png",
      ),
      _TopInfoCard(
        title: "LAPOR DENGAN CEPAT & AMAN",
        subtitle: "Petugas terdekat akan menerima notifikasi Anda",
        image: "assets/phone.png",
      ),
      _TopInfoCard(
        title: "PANTAU ZONA RAWAN",
        subtitle: "Dapatkan informasi wilayah rawan secara real-time",
        image: "assets/logo.png",
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      // backgroundColor: Colors.transparent,
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceGlass, AppColors.surfaceGlass2],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF9FAFF), Colors.white],
                  ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 54, 16, 20),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppGradients.loginButton
                      : const LinearGradient(
                          colors: [Color(0xFF8B5A24), Color(0xFFAA7740)],
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Role: ${_role.isEmpty ? '-' : _role} • Status: $_statusVerif",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              _DrawerTile(
                icon: Icons.map_outlined,
                title: "Maps Lokasi Kejahatan",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CrimeMapPage()),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.flash_on_outlined,
                title: "Lapor Cepat",
                onTap: () {
                  Navigator.pop(context);
                  _guardVerified("Lapor Cepat", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LaporCepatPage()),
                    );
                  });
                },
              ),
              _DrawerTile(
                icon: Icons.list_alt_outlined,
                title: "Daftar Laporan Cepat",
                onTap: () {
                  Navigator.pop(context);
                  _guardVerified("Daftar Laporan Cepat", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DaftarLaporanPage(),
                      ),
                    );
                  });
                },
              ),
              _DrawerTile(
                icon: Icons.folder_open_outlined,
                title: "Daftar Laporan Polisi",
                onTap: () {
                  Navigator.pop(context);
                  _guardVerified("Daftar Laporan Polisi", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DaftarLaporanKepolisianPage(),
                      ),
                    );
                  });
                },
              ),
              _DrawerTile(
                icon: Icons.chat_bubble_outline,
                title: "Komunitas",
                onTap: () {
                  Navigator.pop(context);
                  _openCommunity();
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(),
              ),

              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.themeMode,
                builder: (context, mode, _) {
                  final darkSelected = mode == ThemeMode.dark;

                  return SwitchListTile.adaptive(
                    value: darkSelected,
                    onChanged: (value) async {
                      await ThemeController.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    secondary: Icon(
                      darkSelected
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: darkSelected
                          ? AppColors.accentLight
                          : AppColors.primaryBlue,
                    ),
                    title: Text(darkSelected ? "Mode Gelap" : "Mode Terang"),
                  );
                },
              ),

              _DrawerTile(
                icon: Icons.logout,
                title: "Logout",
                danger: true,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
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
                  color: AppColors.accentPurple.withOpacity(0.12),
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
                  color: AppColors.primaryBlue.withOpacity(0.10),
                ),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceGlass.withOpacity(0.85)
                          : Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderLight2
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? AppColors.shadowDark.withOpacity(0.22)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: isDark
                                ? AppColors.textPrimary
                                : Colors.black87,
                          ),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Selamat Datang, ${widget.username}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            );
                            await _loadEligibility();
                          },
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.white05
                                  : const Color(0xFFF1F4FB),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 20,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    // Padding horizontal dihapus dari sini agar carousel bisa menyentuh pinggir tepi layar
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(0),
                          height: 200,
                          // Menggunakan PageView.builder dipadukan dengan AnimatedBuilder
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: carouselItems.length,
                            itemBuilder: (context, index) {
                              return AnimatedBuilder(
                                animation: pageController,
                                builder: (context, child) {
                                  double value = 1.0;

                                  // Logika untuk menghitung skala (perbesar/perkecil) berdasarkan posisi geser
                                  if (pageController.position.haveDimensions) {
                                    value = pageController.page! - index;
                                    // Semakin jauh dari tengah, skalanya semakin mengecil hingga maksimal 0.85
                                    value = (1 - (value.abs() * 0.15)).clamp(
                                      0.85,
                                      1.0,
                                    );
                                  } else {
                                    // Fallback saat pertama kali render (index 0 skala penuh, sisanya mengecil)
                                    value = index == 0 ? 1.0 : 0.85;
                                  }

                                  return Center(
                                    child: Transform.scale(
                                      scale: Curves.easeOut.transform(value),
                                      child:
                                          child, // child ini adalah carouselItems[index]
                                    ),
                                  );
                                },
                                child: carouselItems[index],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tambahkan padding horizontal di sini untuk GridView
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: featureItems.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.9,
                                ),
                            itemBuilder: (context, index) {
                              final item = featureItems[index];
                              return _FeatureCard(item: item);
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Tambahkan padding horizontal di sini untuk Tombol
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PanicHoldButton(
                            token: widget.token,
                            baseUrl: widget.baseUrl,
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;

  const _TopInfoCard({
    required this.title,
    required this.subtitle,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppGradients.loginButton
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 219, 219, 219),
                ],
              ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.shadowDark.withValues(alpha: 0.28)
                : Colors.black.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    // color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Image.asset("assets/phone2.png", fit: BoxFit.contain),
          Image.asset(image, fit: BoxFit.contain),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  _FeatureItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;

  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final disabled = !item.enabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: disabled ? 0.58 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.bgPurpleDark.withValues(alpha: 0.40)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.borderLight2
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.lightBlue.withValues(alpha: 0.20)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: isDark ? AppColors.primaryBlue : AppColors.bgDeep,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (disabled)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white08
                          : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock,
                          size: 12,
                          color: isDark ? AppColors.textMuted2 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Locked",
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textMuted2
                                : Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = danger
        ? AppColors.danger
        : (isDark ? AppColors.textPrimary : Colors.black87);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
