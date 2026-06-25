import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:mobile_app/theme/app_theme.dart';

class OfficerRouteMapPage extends StatefulWidget {
  final int panicId;
  final double citizenLat;
  final double citizenLng;
  final String citizenName;
  final String address;

  const OfficerRouteMapPage({
    super.key,
    required this.panicId,
    required this.citizenLat,
    required this.citizenLng,
    required this.citizenName,
    required this.address,
  });

  @override
  State<OfficerRouteMapPage> createState() => _OfficerRouteMapPageState();
}

class _OfficerRouteMapPageState extends State<OfficerRouteMapPage> {
  final MapController _map = MapController();
  String? _resolvedAddress;
  bool _loadingAddress = false;

  lat_lng.LatLng? _officerPos;
  late final lat_lng.LatLng _citizenPos = lat_lng.LatLng(
    widget.citizenLat,
    widget.citizenLng,
  );

  StreamSubscription<Position>? _sub;
  Timer? _debounce;

  List<lat_lng.LatLng> _routePoints = [];
  double? _routeDistanceM;
  int? _routeDurationS;

  String _formatDistance(double m) => m < 1000
      ? "${m.toStringAsFixed(0)} m"
      : "${(m / 1000).toStringAsFixed(2)} km";

  String _formatEta(int sec) {
    final mm = (sec / 60).floor();
    if (mm < 60) return "${mm} menit";
    final h = mm ~/ 60;
    final m = mm % 60;
    return "${h}j ${m}m";
  }

  bool _isUsefulAddress(String? value) {
    if (value == null) return false;

    final v = value.trim().toLowerCase();

    return v.isNotEmpty &&
        v != "-" &&
        v != "null" &&
        v != "alamat target tidak tersedia" &&
        v != "tidak tersedia";
  }

  @override
  void initState() {
    super.initState();
    _startOfficerStream();

    // langsung pakai alamat kiriman kalau memang valid
    _resolvedAddress = _isUsefulAddress(widget.address)
        ? widget.address.trim()
        : null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _map.move(_citizenPos, 16);

      // tetap fetch ulang dari koordinat biar sama seperti laporan cepat
      await _fetchTargetAddress();
    });
  }

  Future<void> _fetchTargetAddress() async {
    if (_loadingAddress) return;

    setState(() => _loadingAddress = true);

    try {
      final lat = widget.citizenLat;
      final lng = widget.citizenLng;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=$lat'
        '&lon=$lng'
        '&zoom=18'
        '&addressdetails=1',
      );

      final res = await http.get(
        url,
        headers: {
          // buat lebih jelas identitas app
          'User-Agent': 'SIGAP Mobile/1.0 (contact: your@email.com)',
          'Accept-Language': 'id',
        },
      );

      debugPrint("reverse geocode status: ${res.statusCode}");
      debugPrint("reverse geocode body: ${res.body}");

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final displayName = data['display_name']?.toString();

        setState(() {
          _resolvedAddress =
              (displayName != null && displayName.trim().isNotEmpty)
              ? displayName
              : null;
        });
      } else {
        // jangan paksa "tidak tersedia", biar fallback ke koordinat
        setState(() {
          _resolvedAddress = null;
        });
      }
    } catch (e) {
      debugPrint("reverse geocode error: $e");

      if (!mounted) return;
      setState(() {
        _resolvedAddress = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingAddress = false);
      }
    }
  }

  Future<void> _startOfficerStream() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever)
      return;

    final first = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(
      () => _officerPos = lat_lng.LatLng(first.latitude, first.longitude),
    );
    _fitBounds();
    _scheduleRouteFetch();

    await _sub?.cancel();
    _sub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          setState(
            () => _officerPos = lat_lng.LatLng(pos.latitude, pos.longitude),
          );
          _scheduleRouteFetch();
        });
  }

  void _fitBounds() {
    if (_officerPos == null) return;
    final bounds = LatLngBounds.fromPoints([_officerPos!, _citizenPos]);
    _map.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
    );
  }

  void _scheduleRouteFetch() {
    if (_officerPos == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _fetchOsrmRoute);
  }

  Future<void> _fetchOsrmRoute() async {
    if (_officerPos == null) return;

    final o = _officerPos!;
    final c = _citizenPos;

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
      final dist = (r0["distance"] as num).toDouble();
      final dur = (r0["duration"] as num).round();

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
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = _officerPos;
    final hasRoute = _routePoints.length >= 2;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Rute ke Lokasi",
          style: TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primaryBlue2,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(initialCenter: _citizenPos, initialZoom: 16),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.mobile_app',
              ),
              if (o != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: hasRoute ? _routePoints : [o, _citizenPos],
                      strokeWidth: 4,
                      color: AppColors.success,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _citizenPos,
                    width: 46,
                    height: 46,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                  if (o != null)
                    Marker(
                      point: o,
                      width: 46,
                      height: 46,
                      child: const Icon(
                        Icons.local_police,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              // child: Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Text(
              //       "Tujuan: ${widget.citizenName}",
              //       style: const TextStyle(fontWeight: FontWeight.w800),
              //     ),
              //     const SizedBox(height: 6),
              //     Text(
              //       widget.address,
              //       style: const TextStyle(color: Colors.black54),
              //     ),
              //     const SizedBox(height: 10),
              //     Row(
              //       children: [
              //         Expanded(
              //           child: Text(
              //             "Jarak: ${_routeDistanceM == null ? "-" : _formatDistance(_routeDistanceM!)}",
              //           ),
              //         ),
              //         Expanded(
              //           child: Text(
              //             "Estimasi: ${_routeDurationS == null ? "-" : _formatEta(_routeDurationS!)}",
              //           ),
              //         ),
              //       ],
              //     ),
              //     const SizedBox(height: 10),
              //     Row(
              //       children: [
              //         Expanded(
              //           child: ElevatedButton.icon(
              //             onPressed: _fitBounds,
              //             icon: const Icon(Icons.fit_screen),
              //             label: const Text("Fit"),
              //             style: ElevatedButton.styleFrom(
              //               backgroundColor: const Color(0xFF8B5A24),
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tujuan: ${widget.citizenName}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 85,
                        child: Text(
                          "Latitude",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(": "),
                      Expanded(
                        child: Text(
                          widget.citizenLat.toStringAsFixed(6),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 85,
                        child: Text(
                          "Longitude",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(": "),
                      Expanded(
                        child: Text(
                          widget.citizenLng.toStringAsFixed(6),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 85,
                        child: Text(
                          "Lokasi",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(": "),
                      Expanded(
                        child: Text(
                          _loadingAddress
                              ? "Mengambil nama lokasi target..."
                              : (_resolvedAddress ??
                                    (_isUsefulAddress(widget.address)
                                        ? widget.address
                                        : "${widget.citizenLat.toStringAsFixed(6)}, ${widget.citizenLng.toStringAsFixed(6)}")),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Jarak: ${_routeDistanceM == null ? "-" : _formatDistance(_routeDistanceM!)}",
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Estimasi: ${_routeDurationS == null ? "-" : _formatEta(_routeDurationS!)}",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _fitBounds,
                          icon: const Icon(Icons.fit_screen),
                          label: const Text("Fit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5A24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
