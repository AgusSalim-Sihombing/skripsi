import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:mobile_app/services/socket_service.dart';

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

  // officer position
  double? _officerLat;
  double? _officerLng;
  String _lastUpdate = "-";

  // citizen position
  lat_lng.LatLng? _citizenPos;
  StreamSubscription<Position>? _posSub;

  bool _locReady = false;
  bool _locDenied = false;

  // UI metrics
  double? _distanceM; // meters
  String _etaTextValue = "-"; // ETA text (JANGAN NAMAIN _etaText() juga)

  // follow mode
  bool _followOfficer = true;
  bool _userInteractingWithMap = false;

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

    // ETA: pakai speed dari officer kalau ada dan masuk akal, kalau tidak fallback 8 m/s (~28km/h)
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

  // ===== location stream citizen =====
  Future<void> _startCitizenLocationStream() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locReady = false;
          _locDenied = true;
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locReady = false;
          _locDenied = true;
        });
        return;
      }

      final first = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _citizenPos = lat_lng.LatLng(first.latitude, first.longitude);
        _locReady = true;
        _locDenied = false;
      });

      // update jarak/ETA kalau officer udah ada
      _recalcDistanceAndEta();

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

            // setiap citizen bergerak, recalc jarak/ETA
            _recalcDistanceAndEta();
          });

      // kalau officer udah ada, fit
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fitBoundsIfPossible(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locReady = false;
        _locDenied = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // initial officer position (kalau backend ngirim lastLat lastLng)
    _officerLat = (widget.officer["lastLat"] as num?)?.toDouble();
    _officerLng = (widget.officer["lastLng"] as num?)?.toDouble();

    _startCitizenLocationStream();

    // connect socket (cukup sekali)
    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    // join room panic
    _socket.emit("panic:join", {"panicId": widget.panicId});

    // listen officer location (SATU KALI AJA)
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
      final speed = (data["speed"] as num?)?.toDouble(); // m/s optional

      if (!mounted) return;
      setState(() {
        _officerLat = lat;
        _officerLng = lng;
        _lastUpdate = data["updatedAt"]?.toString() ?? "-";
      });

      // recalc jarak/ETA saat officer update
      _recalcDistanceAndEta(officerSpeedMs: speed);

      if (_followOfficer && !_userInteractingWithMap) {
        _followToOfficer();
      }
    });

    _socket.on("panic:resolved", (payload) {
      final data = Map<String, dynamic>.from(payload);
      final pidRaw = data["panicId"];
      final pid = (pidRaw is num) ? pidRaw.toInt() : int.tryParse("$pidRaw");
      if (pid != widget.panicId) return;

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Penanganan selesai")));
      Navigator.popUntil(context, (route) => route.isFirst);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBoundsIfPossible();
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _socket.emit("panic:leave", {"panicId": widget.panicId});
    _socket.disconnect();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Respon Officer"),
        backgroundColor: primary,
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
                    "✅ Sudah direspon oleh: $officerName",
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
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  if (_locDenied)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "⚠️ Lokasi kamu belum diizinkan. Jarak/ETA bisa kurang akurat.",
                        style: TextStyle(color: Colors.red, fontSize: 12),
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
                              "🧭 Follow OFF (karena kamu geser map)",
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
                            points: [c, o],
                            strokeWidth: 4,
                            color: Colors.blueAccent.withOpacity(0.85),
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
                        "⏳ Nunggu lokasi officer... (pastikan officer app ngirim event officer:location)",
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
