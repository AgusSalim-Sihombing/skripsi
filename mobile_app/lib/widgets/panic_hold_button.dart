import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/pages/panic/panic_waiting_page.dart';

class PanicHoldButton extends StatefulWidget {
  final String token;
  final String baseUrl; // root: http://IP:3001 (tanpa /api)

  const PanicHoldButton({
    super.key,
    required this.token,
    required this.baseUrl,
  });

  @override
  State<PanicHoldButton> createState() => _PanicHoldButtonState();
}

class _PanicHoldButtonState extends State<PanicHoldButton> {
  Timer? _timer;

  double _progress = 0.0; // 0..1 untuk animasi fill
  bool _sending = false;

  static const int _totalMs = 1000; // ✅ 1 detik
  static const int _tickMs = 16; // ~60fps

  void _startHold() {
    if (_sending) return;

    _timer?.cancel();
    setState(() => _progress = 0.0);

    int elapsed = 0;

    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (t) async {
      elapsed += _tickMs;

      final p = (elapsed / _totalMs).clamp(0.0, 1.0);
      if (mounted) setState(() => _progress = p);

      if (elapsed >= _totalMs) {
        t.cancel();
        await _sendPanic();
      }
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    if (mounted) setState(() => _progress = 0.0);
  }

  Future<void> _sendPanic() async {
    try {
      if (mounted) setState(() => _sending = true);

      // permission lokasi
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak")));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final resp = await http.post(
        Uri.parse("${widget.baseUrl}/api/mobile/panic"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "lat": pos.latitude,
          "lng": pos.longitude,
          "address": null,
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final int panicId = (json["panicId"] as num).toInt();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("active_panic_id", panicId);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PanicWaitingPage(
              token: widget.token,
              baseUrl: widget.baseUrl,
              panicId: panicId,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⏳ Menunggu respon officer...")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal kirim panic: ${resp.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _sending = false);
      _cancelHold();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFC62828); // merah utama
    const fillColor = Color(0xFF8E0000); // lebih gelap (pekat)

    final bool isHolding = _progress > 0 && !_sending;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Base button background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                _sending
                    ? "MENGIRIM..."
                    : (isHolding ? "TAHAN..." : "PANIC BUTTON"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),

            // ✅ Fill overlay dari kiri ke kanan (makin pekat)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _progress.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: Container(color: fillColor.withOpacity(0.75)),
                  ),
                ),
              ),
            ),

            // optional: subtle border highlight saat hold
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(isHolding ? 0.45 : 0.20),
                      width: isHolding ? 1.5 : 1,
                    ),
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
