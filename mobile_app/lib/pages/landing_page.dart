import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_app/pages/lapor_cepat.dart/daftar_laporan_cepat.dart';
import 'package:mobile_app/pages/lapor_cepat.dart/laporan_cepat.dart';
import 'package:mobile_app/pages/maps_lokasi_kejahatan/maps_lokasi_kejahatan.dart';
import 'package:mobile_app/pages/rekap_kriminal/rekap_kriminal_page.dart';
import 'package:mobile_app/pages/tentang/tentang_aplikasi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:mobile_app/widgets/panic_hold_button.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/services/background_zone_service.dart';
import 'package:mobile_app/config/api_config.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/community/community_lobby_page.dart';
import 'package:mobile_app/pages/laporan_kepolisian/buat_laporan_kepolisian_page.dart';
import 'package:mobile_app/pages/laporan_kepolisian/daftar_laporan_kepolisian_page.dart';
import 'package:mobile_app/pages/profile_page.dart';

class LandingPage extends StatefulWidget {
  final String username;
  final String token; // ✅ token JWT
  final String baseUrl; // ✅ root server: http://IP:3001 (tanpa /api)

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

  @override
  void initState() {
    super.initState();
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

    // ✅ ping tiap 2 detik biar kita tau UI <-> BG nyambung
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
          content: Text("✅ Sudah direspon oleh officer: ${officer['nama']}"),
        ),
      );
    });

    // biar gak “berantem” sama build awal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootZoneMonitor();
    });

    _loadEligibility();
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

  bool get _isVerified => _statusVerif == 'verified';

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

  Future<void> _logout() async {
    // optional confirm
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
      // stop BG zone monitor
      await BackgroundZoneService.stop();
      await Future.delayed(const Duration(milliseconds: 600));

      // disconnect socket
      _socket.disconnect();

      // clear saved session
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      // balik ke login (hapus semua route sebelumnya)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("❌ logout error: $e");
    }
  }

  Future<void> _bootZoneMonitor() async {
    try {
      debugPrint("🟡 [UI] boot zone monitor...");

      // 1) init notif (channel only). Permission udah dari LOGIN
      await NotificationService.init();

      // 2) configure BG service (idempotent)
      await BackgroundZoneService.init();

      // 3) cek lokasi (jangan request di sini)
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        debugPrint("⚠️ [UI] GPS mati");
        return;
      }

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        debugPrint("⚠️ [UI] izin lokasi belum ada (harusnya udah di login)");
        return;
      }

      // 4) fetch zona
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode != 200) {
        debugPrint("❌ [UI] fetch zona gagal: ${res.statusCode} ${res.body}");
        return;
      }

      final decoded = jsonDecode(res.body);
      final List data = decoded['data'] as List;

      final zones = data.map((e) => Map<String, dynamic>.from(e)).toList();
      await BackgroundZoneService.saveZones(zones);

      debugPrint("✅ [UI] BG zones saved: ${zones.length}");

      // 5) HARD RESTART biar gak nyangkut service lama
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
      // ✅ pastiin izin lokasi udah "Always"
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

      // ✅ ambil zona dari backend (punya radius_meter)
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mobile/zona-bahaya'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] as List;

        // ✅ mapping sesuai schema kamu
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

      // ✅ start service (biar jalan walau app di-close)
      await BackgroundZoneService.restartHard();
      debugPrint("✅ [UI] BG service restarted hard");
    } catch (e) {
      debugPrint("❌ _setupZonaBahayaMonitoring error: $e");
    }
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
        icon: Icons.flash_on_outlined,
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
          // TODO: halaman rekapan kriminal
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
          // TODO: halaman tentang aplikasi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TentangAplikasiPage()),
          );
        },
      ),
    ];

    final pageController = PageController(viewportFraction: 0.9);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF8B5A24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                  const SizedBox(height: 10),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("SIGAP", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text("Maps Lokasi Kejahatan"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrimeMapPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_outlined),
              title: const Text("Lapor Cepat"),
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
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text("Daftar Laporan Cepat"),
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

            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text("Daftar Laporan Polisi"),
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

            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text("Komunitas"),
              onTap: () {
                Navigator.pop(context);
                _openCommunity();
              },
            ),

            const Divider(),

            // ✅ Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            // ---------- HEADER ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Selamat Datang, ${widget.username}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                      // ✅ habis balik dari profile, reload status
                      await _loadEligibility();
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: const CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.person),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------- SLIDER CARD ATAS ----------
                    SizedBox(
                      height: 150,
                      child: PageView(
                        controller: pageController,
                        children: const [
                          _TopInfoCard(
                            title: "APLIKASI SIAGA SIAP MEMBANTU ANDA",
                            subtitle: "Tindak Lanjuti Segala Bentuk Kriminal",
                          ),
                          _TopInfoCard(
                            title: "LAPOR DENGAN CEPAT & AMAN",
                            subtitle:
                                "Petugas terdekat akan menerima notifikasi Anda",
                          ),
                          _TopInfoCard(
                            title: "LAPOR DENGAN CEPAT & AMAN",
                            subtitle:
                                "Petugas terdekat akan menerima notifikasi Anda",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---------- GRID 6 FITUR ----------
                    GridView.builder(
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

                    const SizedBox(height: 32),

                    // ---------- PANIC BUTTON ----------
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
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
    );
  }
}

// ===================================================================
//  WIDGET KARTU ATAS (COLORED SLIDER)
// ===================================================================
class _TopInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TopInfoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5A24), // coklat
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // teks kiri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ilustrasi dummy kanan (pakai icon dulu)
          const Icon(Icons.shield_moon_outlined, color: Colors.white, size: 60),
        ],
      ),
    );
  }
}

// ===================================================================
//  MODEL & CARD UNTUK FITUR
// ===================================================================
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

    return InkWell(
      onTap: item.onTap, // tetap bisa tap biar muncul dialog
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
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
                    Icon(item.icon, color: const Color(0xFF8B5A24), size: 30),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                      color: Colors.black.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.black54),
                        SizedBox(width: 4),
                        Text(
                          "Locked",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
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
