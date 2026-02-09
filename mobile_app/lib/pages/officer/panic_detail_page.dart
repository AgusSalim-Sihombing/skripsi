import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/services/socket_service.dart';

class PanicDetailPage extends StatefulWidget {
  final String token;
  final String baseUrl; // http://IP:3001
  final Map<String, dynamic> panicData; // payload dari socket panic:new

  const PanicDetailPage({
    super.key,
    required this.token,
    required this.baseUrl,
    required this.panicData,
  });

  @override
  State<PanicDetailPage> createState() => _PanicDetailPageState();
}

class _PanicDetailPageState extends State<PanicDetailPage> {
  bool _isResponding = false;
  bool _isResolving = false;
  bool _responded = false;
  StreamSubscription<Position>? _distanceSub;
  StreamSubscription<Position>? _shareLocSub;
  double? _distanceMeters;
  String _distanceText = "-";
  bool _distanceDenied = false;

  final SocketService _socket = SocketService();
  double? _myLat;
  double? _myLng;

  Map<String, dynamic>? _citizen; // data citizen dari API respond
  String? _statusText;

  int get _panicId => (widget.panicData["panicId"] as num).toInt();

  double get _lat => (widget.panicData["lat"] as num).toDouble();

  double get _lng => (widget.panicData["lng"] as num).toDouble();

  String get _fromName => (widget.panicData["fromName"] ?? "-").toString();

  String get _address =>
      (widget.panicData["address"] ?? "${_lat}, ${_lng}").toString();

  String get _distanceM => (widget.panicData["distanceM"] ?? "-").toString();

  @override
  void initState() {
    super.initState();
    _statusText = "Status: Menunggu aksi officer…";
    _startDistanceWatcher();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return "${meters.toStringAsFixed(0)} m";
    return "${(meters / 1000).toStringAsFixed(2)} km";
  }

  Future<void> _startShareLocation() async {
    // connect socket (kalau belum)
    _socket.connect(baseUrl: widget.baseUrl, token: widget.token);

    // JOIN ROOM PANIC (INI YANG PENTING)
    _socket.emit("panic:join", {"panicId": _panicId});

    // permission lokasi
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Izin lokasi ditolak (officer)")),
        );
      }
      return;
    }

    // 🚀 kirim 1x lokasi dulu biar citizen langsung dapet (stream kadang telat)
    try {
      final first = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _socket.emit("officer:location", {
        "panicId": _panicId,
        "lat": first.latitude,
        "lng": first.longitude,
        "speed": first.speed,
        "updatedAt": DateTime.now().toIso8601String(),
      });

      debugPrint(
        "📤 emit officer:location FIRST => ${first.latitude}, ${first.longitude}",
      );
    } catch (_) {}

    // stop stream lama khusus share location
    await _shareLocSub?.cancel();

    // mulai stream lokasi officer
    _shareLocSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          _myLat = pos.latitude;
          _myLng = pos.longitude;

          // DEBUG biar kelihatan ngirim
          debugPrint(
            "📤 emit officer:location => panic=$_panicId lat=${pos.latitude} lng=${pos.longitude} socketConnected=${_socket.isConnected}",
          );

          _socket.emit("officer:location", {
            "panicId": _panicId,
            "lat": pos.latitude,
            "lng": pos.longitude,
            "speed": pos.speed,
            "updatedAt": DateTime.now().toIso8601String(),
          });
        });
  }

  Future<void> _stopShareLocation() async {
    await _shareLocSub?.cancel();
    _shareLocSub = null;

    // optional: leave room
    _socket.emit("panic:leave", {"panicId": _panicId});
  }

  Future<void> _startDistanceWatcher() async {
    try {
      // permission lokasi
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _distanceDenied = true;
          _distanceText = "-";
        });
        return;
      }

      // ambil sekali dulu biar langsung muncul
      final first = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final d0 = Geolocator.distanceBetween(
        first.latitude,
        first.longitude,
        _lat,
        _lng,
      );

      if (!mounted) return;
      setState(() {
        _distanceDenied = false;
        _distanceMeters = d0;
        _distanceText = _formatDistance(d0);
      });

      // realtime update
      await _distanceSub?.cancel();
      _distanceSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((pos) {
            final d = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              _lat,
              _lng,
            );

            if (!mounted) return;
            setState(() {
              _distanceMeters = d;
              _distanceText = _formatDistance(d);
            });
          });
    } catch (_) {
      if (!mounted) return;
      setState(() => _distanceText = "-");
    }
  }

  Future<void> _callRespond() async {
    if (_isResponding || _responded) return;

    setState(() {
      _isResponding = true;
      _statusText = "Status: Mengambil kasus (respond)…";
    });

    try {
      final resp = await http.post(
        Uri.parse(
          "${widget.baseUrl}/api/mobile/officer/panic/$_panicId/respond",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (resp.statusCode == 200) {
        await _startShareLocation();
        final json = jsonDecode(resp.body);
        setState(() {
          _citizen = json["citizen"];
          _responded = true; // ✅ sukses baru true
          _statusText = "Status: Sedang merespon (ACTIVE)";
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Respon berhasil diambil. Kamu sekarang BUSY."),
            ),
          );
        }
      } else if (resp.statusCode == 409) {
        setState(() {
          _statusText = "Status: Panic sudah diambil officer lain.";
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ Panic sudah diambil officer lain."),
            ),
          );
        }
      } else {
        setState(() {
          _statusText = "Status: Gagal respond.";
        });
      }
    } catch (e) {
      setState(() => _statusText = "Status: Error saat respond.");
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  Future<void> _callResolve() async {
    if (_isResolving) return;

    setState(() {
      _isResolving = true;
      _statusText = "Status: Menyelesaikan respon…";
    });

    try {
      final resp = await http.post(
        Uri.parse(
          "${widget.baseUrl}/api/mobile/officer/panic/$_panicId/resolve",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (resp.statusCode == 200) {
        await _stopShareLocation();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Respon selesai. Kamu kembali AVAILABLE."),
            ),
          );
          Navigator.pop(context); // balik ke home
        }
      } else {
        setState(() {
          _statusText = "Status: Gagal resolve.";
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal: ${resp.body}")));
        }
      }
    } catch (e) {
      setState(() {
        _statusText = "Status: Error saat resolve.";
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Future<void> _openGoogleMapsNav() async {
    final uri = Uri.parse("google.navigation:q=$_lat,$_lng&mode=d");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final web = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lng",
      );
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _distanceSub?.cancel();
    _stopShareLocation();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citizenName = (_citizen?["nama"] ?? _fromName).toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panic Detail"),
        backgroundColor: const Color(0xFF8B5A24),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PANGGILAN DARURAT!!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Dari : $citizenName",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Lokasi : $_address",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Jarak : ${_distanceDenied ? '-' : _distanceText}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusText ?? "-",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // tombol aksi
            ElevatedButton.icon(
              onPressed: (_responded || _isResponding) ? null : _callRespond,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isResponding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                "AMBIL / RESPON",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _responded ? _openGoogleMapsNav : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text(
                "BUKA RUTE (GOOGLE MAPS)",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: (!_responded || _isResolving) ? null : _callResolve,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isResolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.done_all, color: Colors.white),
              label: const Text(
                "SELESAIKAN RESPON",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!_responded)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Ambil/Respon dulu biar tombol Selesaikan aktif.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
