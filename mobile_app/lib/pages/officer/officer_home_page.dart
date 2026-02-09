import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login_page.dart';
import 'package:mobile_app/pages/maps_lokasi_kejahatan/maps_lokasi_kejahatan.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/pages/officer/panic_detail_page.dart';
import 'package:mobile_app/pages/officer/panic_dispatch_page.dart';
import 'package:mobile_app/pages/profile_page.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:mobile_app/widgets/panic_banner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/pages/officer/field_report_inbox_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/pages/officer/panic_history_page.dart';


class OfficerHomePage extends StatefulWidget {
  final String username;
  final String token;
  final String baseUrl; // http://IP:3001 (tanpa /api)

  const OfficerHomePage({
    super.key,
    required this.username,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<OfficerHomePage> createState() => _OfficerHomePageState();
}

class _OfficerHomePageState extends State<OfficerHomePage> {
  final SocketService _socket = SocketService();
  final List<Map<String, dynamic>> _panicNotifs = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Timer? _locTimer;
  bool _isOnDuty = true; // default ON dulu biar gampang testing

  @override
  void initState() {
    super.initState();
    _startLocationHeartbeat();

    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    _socket.on("socket:ready", (data) {
      debugPrint("✅ socket ready: $data");
    });

    _socket.on("panic:new", (payload) {
      final data = Map<String, dynamic>.from(payload);
      final panicId = data["panicId"];

      setState(() {
        // anti duplikat berdasarkan panicId
        final exists = _panicNotifs.any((e) => e["panicId"] == panicId);
        if (!exists) _panicNotifs.add(data);
      });
    });

    // kalau panic sudah di-assign (diambil salah satu officer), hapus dari notifikasi list
    _socket.on("panic:assigned", (payload) {
      final data = Map<String, dynamic>.from(payload);
      final panicId = data["panicId"];

      setState(() {
        _panicNotifs.removeWhere((e) => e["panicId"] == panicId);
      });
    });
  }

  Future<void> _sendOfficerLocationOnce() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        debugPrint("❌ lokasi officer ditolak");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final resp = await http.post(
        Uri.parse("${widget.baseUrl}/api/mobile/officer/location"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "lat": pos.latitude,
          "lng": pos.longitude,
          "isOnDuty": _isOnDuty ? 1 : 0,
        }),
      );

      debugPrint("📍 officer location update: ${resp.statusCode}");
    } catch (e) {
      debugPrint("❌ _sendOfficerLocationOnce error: $e");
    }
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

  void _startLocationHeartbeat() {
    _locTimer?.cancel();

    // kirim sekali langsung
    _sendOfficerLocationOnce();

    _locTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _sendOfficerLocationOnce();
    });
  }

  @override
  void dispose() {
    _locTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featureItems = [
      _OfficerFeatureItem(
        title: "Panic Dispatch",
        icon: Icons.warning_amber_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PanicDispatchPage(
                token: widget.token,
                baseUrl: widget.baseUrl,
              ),
            ),
          );
        },
      ),
      _OfficerFeatureItem(
        title: "Crime Map (Officer)",
        icon: Icons.map_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrimeMapPage()),
          );
        },
      ),
      _OfficerFeatureItem(
        title: "Field Report",
        icon: Icons.description_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OfficerFieldReportInboxPage(),
            ),
          );
        },
      ),
      _OfficerFeatureItem(
        title: "Riwayat Panic",
        icon: Icons.history_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PanicHistoryPage(
                token: widget.token,
                baseUrl: widget.baseUrl,
              ),
            ),
          );
        },
      ),
      _OfficerFeatureItem(
        title: "Profil Officer",
        icon: Icons.person_outline,
        onTap: () {
          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
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
                  const CircleAvatar(
                    radius: 22,
                    child: Icon(Icons.shield_outlined),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Officer",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: const Text("Panic Dispatch"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PanicDispatchPage(
                      token: widget.token,
                      baseUrl: widget.baseUrl,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text("Case Inbox"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OfficerCaseInboxPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text("Field Report"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OfficerFieldReportInboxPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text("Crime Map"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrimeMapPage()),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Keluar", style: TextStyle(color: Colors.red)),
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
        child: Stack(
          children: [
            Column(
              children: [
                // ---------- HEADER ----------
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Dashboard Officer",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.username,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
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

                // ---------- BODY ----------
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 150,
                          child: PageView(
                            controller: pageController,
                            children: const [
                              _TopOfficerCard(
                                title: "MODE ON DUTY",
                                subtitle:
                                    "Pantau laporan masuk dan panic button di area tugasmu.",
                              ),
                              _TopOfficerCard(
                                title: "PANTAU PANIC REAL-TIME",
                                subtitle:
                                    "Terima notifikasi panic dan ambil rute tercepat ke TKP.",
                              ),
                              _TopOfficerCard(
                                title: "LAPORKAN TINDAKAN LAPANGAN",
                                subtitle:
                                    "Catat hasil penanganan dan update status kasus.",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

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
                            return _OfficerFeatureCard(item: item);
                          },
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PanicDispatchPage(
                                    token: widget.token,
                                    baseUrl: widget.baseUrl,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.warning_amber_rounded),
                            label: const Text(
                              "BUKA PANIC DISPATCH",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ====== NOTIF STACK (multi banner) ======
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: _panicNotifs.map((data) {
                      final isTaking = data["_taking"] == true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PanicBannerCard(
                          data: data,
                          isTaking: isTaking,

                          // ✅ FIX UTAMA: tombol RESPON cuma buka detail, gak hit API respond
                          onRespond: () async {
                            if (isTaking) return;

                            // optional: kasih state "membuka" biar tombol disabled sebentar
                            setState(() {
                              final idx = _panicNotifs.indexWhere(
                                (e) => e["panicId"] == data["panicId"],
                              );
                              if (idx != -1)
                                _panicNotifs[idx]["_taking"] = true;
                            });

                            if (!mounted) return;

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PanicDetailPage(
                                  token: widget.token,
                                  baseUrl: widget.baseUrl,
                                  panicData: data,
                                ),
                              ),
                            );

                            // balik dari detail -> enable lagi (kalau notif masih ada)
                            if (!mounted) return;
                            setState(() {
                              final idx = _panicNotifs.indexWhere(
                                (e) => e["panicId"] == data["panicId"],
                              );
                              if (idx != -1)
                                _panicNotifs[idx].remove("_taking");
                            });
                          },

                          onClose: () {
                            setState(() {
                              _panicNotifs.removeWhere(
                                (e) => e["panicId"] == data["panicId"],
                              );
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
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
//  KARTU ATAS KHUSUS OFFICER
// ===================================================================
class _TopOfficerCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TopOfficerCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5A24),
        borderRadius: BorderRadius.circular(20),
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
          const Icon(
            Icons.local_police_outlined,
            color: Colors.white,
            size: 60,
          ),
        ],
      ),
    );
  }
}

// ===================================================================
//  MODEL & CARD UNTUK FITUR OFFICER
// ===================================================================
class _OfficerFeatureItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _OfficerFeatureItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _OfficerFeatureCard extends StatelessWidget {
  final _OfficerFeatureItem item;

  const _OfficerFeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: const Color(0xFF8B5A24), size: 30),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
//  PLACEHOLDER PAGES
// ===================================================================

class OfficerCaseInboxPage extends StatelessWidget {
  const OfficerCaseInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Case Inbox"),
        backgroundColor: const Color(0xFF8B5A24),
      ),
      body: const Center(
        child: Text("Daftar laporan yang ditugaskan ke officer."),
      ),
    );
  }
}

class OfficerFieldReportPage extends StatelessWidget {
  const OfficerFieldReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Field Report"),
        backgroundColor: const Color(0xFF8B5A24),
      ),
      body: const Center(
        child: Text("Form untuk mengisi laporan hasil penanganan di lapangan."),
      ),
    );
  }
}


