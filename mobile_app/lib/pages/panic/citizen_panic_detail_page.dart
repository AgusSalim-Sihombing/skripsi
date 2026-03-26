import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:mobile_app/pages/landing_page.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CitizenPanicDetailPage extends StatefulWidget {
  final String token;
  final String baseUrl;
  final int panicId;
  final Map<String, dynamic> officer;

  const CitizenPanicDetailPage({
    super.key,
    required this.token,
    required this.baseUrl,
    required this.panicId,
    required this.officer,
  });

  @override
  State<CitizenPanicDetailPage> createState() => _CitizenPanicDetailPageState();
}

class _CitizenPanicDetailPageState extends State<CitizenPanicDetailPage> {
  final SocketService _socket = SocketService();
  final MapController _mapController = MapController();
  final _distanceCalc = const lat_lng.Distance();

  // route (OSRM)
  List<lat_lng.LatLng> _routePoints = [];
  double? _routeDistanceM;
  int? _routeDurationS;
  Timer? _routeDebounce;

  // officer position
  double? _officerLat;
  double? _officerLng;
  String _lastUpdate = "-";

  // citizen position
  lat_lng.LatLng? _citizenPos;
  StreamSubscription<Position>? _posSub;

  bool _locDenied = false;

  // UI metrics
  double? _distanceM; // meters
  String _etaTextValue = "-";

  // follow mode
  bool _followOfficer = true;
  bool _userInteractingWithMap = false;
  bool _didFitOnce = false;

  lat_lng.LatLng? get _officerPos {
    if (_officerLat == null || _officerLng == null) return null;
    return lat_lng.LatLng(_officerLat!, _officerLng!);
  }

  // ===== helpers =====
  String _formatDistance(double m) {
    if (m < 1000) return "${m.toStringAsFixed(0)} m";
    return "${(m / 1000).toStringAsFixed(2)} km";
  }

  String _formatEtaSeconds(int seconds) {
    final mm = (seconds / 60).floor();
    final ss = seconds % 60;
    if (mm <= 0) return "${ss}s";
    if (mm < 60) return "${mm}m ${ss}s";
    final h = mm ~/ 60;
    final m = mm % 60;
    return "${h}j ${m}m";
  }

  void _recalcDistanceAndEta({double? officerSpeedMs}) {
    final o = _officerPos;
    final c = _citizenPos;

    if (o == null || c == null) {
      setState(() {
        _distanceM = null;
        _etaTextValue = "-";
      });
      return;
    }

    final meters = _distanceCalc.as(lat_lng.LengthUnit.Meter, c, o);

    // ETA fallback: 8 m/s (~28 km/h)
    final v = (officerSpeedMs != null && officerSpeedMs > 1)
        ? officerSpeedMs
        : 8.0;
    final seconds = (meters / v).round();

    setState(() {
      _distanceM = meters;
      _etaTextValue = _formatEtaSeconds(seconds);
    });
  }

  void _followToOfficer() {
    final o = _officerPos;
    if (o == null) return;

    final z = _mapController.camera.zoom;
    _mapController.move(o, z < 3 ? 15 : z);
  }

  void _fitBoundsIfPossible() {
    final o = _officerPos;
    final c = _citizenPos;
    if (o == null || c == null) return;

    final bounds = LatLngBounds.fromPoints([
      lat_lng.LatLng(c.latitude, c.longitude),
      lat_lng.LatLng(o.latitude, o.longitude),
    ]);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
    );
  }

  Future<void> _exitToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("active_panic_id");

    // ambil username dari prefs biar LandingPage gak kosong
    final username = prefs.getString("username") ?? "User";

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LandingPage(
          username: username,
          token: widget.token,
          baseUrl: widget.baseUrl,
        ),
      ),
      (route) => false, // ✅ bersihin semua stack
    );
  }

  // ===== location stream citizen =====
  Future<void> _startCitizenLocationStream() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _locDenied = true);
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locDenied = true);
        return;
      }

      final first = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _citizenPos = lat_lng.LatLng(first.latitude, first.longitude);
        _locDenied = false;
      });

      _recalcDistanceAndEta();
      _scheduleRouteFetch();
      if (!_didFitOnce && _officerPos != null && _citizenPos != null) {
        _didFitOnce = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _fitBoundsIfPossible(),
        );
      }

      // stream posisi user
      await _posSub?.cancel();
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((pos) {
            if (!mounted) return;
            setState(() {
              _citizenPos = lat_lng.LatLng(pos.latitude, pos.longitude);
            });

            _recalcDistanceAndEta();
            _scheduleRouteFetch();
          });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locDenied = true);
    }
  }

  void _scheduleRouteFetch() {
    // butuh 2 posisi
    if (_citizenPos == null || _officerPos == null) return;

    _routeDebounce?.cancel();
    _routeDebounce = Timer(const Duration(seconds: 2), () async {
      final c = _citizenPos!;
      final o = _officerPos!;

      // route yang lebih masuk akal: OFFICER -> CITIZEN
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
        "${o.longitude},${o.latitude};${c.longitude},${c.latitude}"
        "?overview=full&geometries=geojson",
      );

      try {
        final resp = await http.get(url);
        if (resp.statusCode != 200) return;

        final json = jsonDecode(resp.body);
        final routes = (json["routes"] as List?) ?? [];
        if (routes.isEmpty) return;

        final r0 = routes[0];
        final dist = (r0["distance"] as num).toDouble(); // meters
        final dur = (r0["duration"] as num).round(); // seconds

        final coords = r0["geometry"]["coordinates"] as List; // [lng,lat]
        final pts = coords.map((p) {
          final lng = (p[0] as num).toDouble();
          final lat = (p[1] as num).toDouble();
          return lat_lng.LatLng(lat, lng);
        }).toList();

        if (!mounted) return;
        setState(() {
          _routePoints = pts;
          _routeDistanceM = dist;
          _routeDurationS = dur;

          // override metric UI pakai route (lebih akurat dari garis lurus)
          _distanceM = dist;
          _etaTextValue = _formatEtaSeconds(dur);
        });
      } catch (_) {}
    });
  }

  @override
  void initState() {
    super.initState();

    // initial officer position (kalau backend ngirim lastLat lastLng)
    _officerLat = (widget.officer["lastLat"] as num?)?.toDouble();
    _officerLng = (widget.officer["lastLng"] as num?)?.toDouble();

    _startCitizenLocationStream();

    // connect socket (singleton) - jangan disconnect di page
    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    // join room panic setelah ready
    _socket.on("socket:ready", (_) {
      _socket.emit("panic:join", {"panicId": widget.panicId});
    });

    // ✅ LISTENER TUNGGAL (hapus yang dobel)
    _socket.on("officer:location", (payload) {
      final data = Map<String, dynamic>.from(payload);

      final pidRaw = data["panicId"];
      final pid = (pidRaw is num) ? pidRaw.toInt() : int.tryParse("$pidRaw");
      if (pid == null || pid != widget.panicId) return;

      final latRaw = data["lat"];
      final lngRaw = data["lng"];
      if (latRaw == null || lngRaw == null) return;

      final lat = (latRaw as num).toDouble();
      final lng = (lngRaw as num).toDouble();
      final speed = (data["speed"] as num?)?.toDouble();

      if (!mounted) return;
      setState(() {
        _officerLat = lat;
        _officerLng = lng;
        _lastUpdate = data["updatedAt"]?.toString() ?? "-";
      });

      _recalcDistanceAndEta(officerSpeedMs: speed);
      _scheduleRouteFetch();

      // fit sekali saat dua titik sudah ada
      if (!_didFitOnce && _officerPos != null && _citizenPos != null) {
        _didFitOnce = true;
        _fitBoundsIfPossible();
      }

      if (_followOfficer && !_userInteractingWithMap) {
        _followToOfficer();
      }
    });

    // kalau officer selesaikan -> citizen balik home
    _socket.on("panic:resolved", (payload) async {
      final data = Map<String, dynamic>.from(payload);
      final pidRaw = data["panicId"];
      final pid = (pidRaw is num) ? pidRaw.toInt() : int.tryParse("$pidRaw");
      if (pid == null || pid != widget.panicId) return;

      await _exitToHome();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBoundsIfPossible();
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _routeDebounce?.cancel();

    _socket.emit("panic:leave", {"panicId": widget.panicId});
    _socket.off("officer:location");
    _socket.off("panic:resolved");
    _socket.off("socket:ready");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final officerName = (widget.officer["nama"] ?? "Officer").toString();
    const primary = Color(0xFF8B5A24);

    final centerFallback =
        _citizenPos ??
        _officerPos ??
        const lat_lng.LatLng(-6.200000, 106.816666);

    final o = _officerPos;
    final c = _citizenPos;
    final hasRoute = _routePoints.length >= 2;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        // kalau user pencet back HP, kita pulang ke beranda (biar gak nyangkut)
        if (!didPop) return;
        await _exitToHome();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Detail Respon Officer"),
          backgroundColor: primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _exitToHome,
          ),
        ),
        body: Column(
          children: [
            // ==== TOP INFO CARD ====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sudah direspon oleh: $officerName",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Panic ID: ${widget.panicId}"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniPill(
                          label: "Jarak",
                          value: _distanceM == null
                              ? "-"
                              : _formatDistance(_distanceM!),
                          icon: Icons.social_distance_rounded,
                        ),
                        const SizedBox(width: 10),
                        _MiniPill(
                          label: "Estimasi",
                          value: _etaTextValue,
                          icon: Icons.timelapse_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Last update officer: $_lastUpdate",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    if (_locDenied)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "Lokasi kamu belum diizinkan. Jarak/ETA bisa kurang akurat.",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    if (_routeDistanceM != null && _routeDurationS != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Route: ${_formatDistance(_routeDistanceM!)} • ${_formatEtaSeconds(_routeDurationS!)}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ==== MAP ====
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centerFallback,
                      initialZoom: 15,
                      onPositionChanged: (pos, hasGesture) {
                        if (!hasGesture) return;

                        _userInteractingWithMap = true;

                        if (_followOfficer) {
                          setState(() => _followOfficer = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Follow OFF (karena kamu geser map)",
                              ),
                              duration: Duration(milliseconds: 900),
                            ),
                          );
                        }

                        Future.delayed(const Duration(seconds: 2), () {
                          _userInteractingWithMap = false;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.mobile_app',
                      ),

                      if (c != null && o != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: hasRoute ? _routePoints : [o, c],
                              strokeWidth: 4,
                              color: const Color.fromARGB(255, 0, 94, 255).withOpacity(0.85),
                            ),
                          ],
                        ),

                      MarkerLayer(
                        markers: [
                          if (c != null)
                            Marker(
                              point: c,
                              width: 46,
                              height: 46,
                              child: const _DotMarker(
                                label: "Kamu",
                                color: Colors.blue,
                                icon: Icons.person_pin_circle_rounded,
                              ),
                            ),
                          if (o != null)
                            Marker(
                              point: o,
                              width: 46,
                              height: 46,
                              child: const _DotMarker(
                                label: "Officer",
                                color: Colors.red,
                                icon: Icons.local_police_rounded,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // floating buttons
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          heroTag: "follow_officer",
                          backgroundColor: _followOfficer
                              ? primary
                              : Colors.white,
                          onPressed: () {
                            setState(() => _followOfficer = !_followOfficer);

                            if (_followOfficer) {
                              _followToOfficer();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("✅ Follow Officer ON"),
                                  duration: Duration(milliseconds: 900),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("🧭 Follow Officer OFF"),
                                  duration: Duration(milliseconds: 900),
                                ),
                              );
                            }
                          },
                          child: Icon(
                            _followOfficer
                                ? Icons.navigation_rounded
                                : Icons.navigation_outlined,
                            color: _followOfficer ? Colors.white : primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: "fit_bounds",
                          backgroundColor: primary,
                          onPressed: _fitBoundsIfPossible,
                          child: const Icon(Icons.fit_screen_rounded),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: "center_me",
                          backgroundColor: Colors.white,
                          onPressed: () {
                            if (_citizenPos == null) return;
                            _mapController.move(_citizenPos!, 16);
                          },
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // hint kalau officer belum ngirim lokasi
                  if (o == null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          "⏳ Nunggu lokasi officer... (cek socket officer:location)",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== UI HELPERS =====

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotMarker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _DotMarker({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        Positioned(
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}
